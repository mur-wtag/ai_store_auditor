module ApplicationHelper
  def audit_money(cents, currency: "USD")
    number_to_currency(cents.to_i / 100.0, unit: "#{currency.presence || 'USD'} ", precision: 0)
  end

  def score_tone(score)
    return "critical" if score.to_i < 55
    return "warning" if score.to_i < 75

    "success"
  end

  def evidence_label(key)
    key.to_s.humanize
  end
end
