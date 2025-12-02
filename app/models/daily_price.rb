class DailyPrice < ApplicationRecord
  validates :symbol, presence: true
  validates :date, presence: true, uniqueness: { scope: :symbol }
  validates :open, :high, :low, :close, presence: true, numericality: { greater_than: 0 }
  validates :volume, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validate :high_must_be_highest
  validate :low_must_be_lowest

  scope :for_symbol, ->(symbol) { where(symbol: symbol) }
  scope :in_date_range, ->(from, to) { where(date: from..to) }
  scope :recent, ->(days = 30) { where("date >= ?", days.days.ago).order(date: :desc) }

  private

  def high_must_be_highest
    if high.present? && (high < open || high < close || high < low)
      errors.add(:high, "必須是最高價")
    end
  end

  def low_must_be_lowest
    if low.present? && (low > open || low > close || low > high)
      errors.add(:low, "必須是最低價")
    end
  end
end
