# frozen_string_literal: true

require "net/http"

class OpenaiAuditEnricher
  class Error < StandardError; end

  ENDPOINT = URI("https://api.openai.com/v1/responses")
  MAX_FINDINGS = 10

  def self.available?
    ENV["OPENAI_API_KEY"].present?
  end

  def initialize(api_key: ENV["OPENAI_API_KEY"], model: ENV.fetch("OPENAI_MODEL", "gpt-5.6-terra"))
    @api_key = api_key
    @model = model
  end

  attr_reader :model

  def enrich(findings)
    selected = Array(findings).first(MAX_FINDINGS)
    return [] if selected.empty?
    raise Error, "OPENAI_API_KEY is not configured" if @api_key.blank?

    response = request(payload(selected))
    result = JSON.parse(extract_output_text(response))
    items = result.fetch("findings")
    apply(items, selected)
    items
  rescue JSON::ParserError, KeyError => error
    raise Error, "OpenAI returned an invalid structured response: #{error.message}"
  end

  private

  def payload(findings)
    {
      model: model,
      store: false,
      reasoning: { effort: "low" },
      input: [
        {
          role: "system",
          content: <<~PROMPT
            You are a careful Shopify conversion consultant. Explain only the supplied evidence.
            Never promise revenue, invent store facts, create fake reviews, or recommend false urgency.
            Keep advice specific, short, merchant-readable, and safe to publish. If copy depends on
            unknown product facts, provide a fill-in template and state what the merchant must verify.
          PROMPT
        },
        {
          role: "user",
          content: JSON.generate(findings.map { |finding| finding_payload(finding) })
        }
      ],
      text: {
        format: {
          type: "json_schema",
          name: "store_audit_enrichment",
          strict: true,
          schema: response_schema
        }
      }
    }
  end

  def finding_payload(finding)
    {
      finding_id: finding.id,
      title: finding.title.to_s.truncate(180),
      resource_title: finding.resource_title.to_s.truncate(180),
      explanation: finding.explanation.to_s.truncate(700),
      recommendation: finding.recommendation.to_s.truncate(700),
      evidence: finding.evidence
    }
  end

  def response_schema
    {
      type: "object",
      additionalProperties: false,
      required: [ "findings" ],
      properties: {
        findings: {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            required: %w[finding_id merchant_explanation suggested_copy implementation_steps caution],
            properties: {
              finding_id: { type: "integer" },
              merchant_explanation: { type: "string" },
              suggested_copy: { type: "string" },
              implementation_steps: { type: "array", items: { type: "string" } },
              caution: { type: "string" }
            }
          }
        }
      }
    }
  end

  def request(body)
    response = Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true, open_timeout: 5, read_timeout: 90) do |http|
      request = Net::HTTP::Post.new(ENDPOINT)
      request["Authorization"] = "Bearer #{@api_key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(body)
      http.request(request)
    end

    parsed = JSON.parse(response.body)
    return parsed if response.is_a?(Net::HTTPSuccess)

    message = parsed.dig("error", "message") || "HTTP #{response.code}"
    raise Error, "OpenAI request failed: #{message.to_s.truncate(500)}"
  rescue JSON::ParserError => error
    raise Error, "OpenAI returned unreadable JSON: #{error.message}"
  end

  def extract_output_text(response)
    content = Array(response["output"]).flat_map { |item| Array(item["content"]) }
    refusal = content.find { |item| item["type"] == "refusal" }
    raise Error, "OpenAI declined the enrichment: #{refusal['refusal']}" if refusal

    output = content.find { |item| item["type"] == "output_text" }
    raise Error, "OpenAI response did not contain output text" unless output&.dig("text").present?

    output.fetch("text")
  end

  def apply(items, findings)
    findings_by_id = findings.index_by(&:id)

    items.each do |item|
      finding = findings_by_id[item.fetch("finding_id")]
      next unless finding

      finding.update!(ai_draft: item.except("finding_id"))
    end
  end
end
