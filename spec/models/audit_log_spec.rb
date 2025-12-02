require 'rails_helper'

RSpec.describe AuditLog, type: :model do
  let(:user) { create(:user) }

  describe 'validations' do
    it '需要 user' do
      audit_log = AuditLog.new(action: 'deposit')
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:user]).to be_present
    end

    it '需要 action' do
      audit_log = AuditLog.new(user: user)
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:action]).to be_present
    end

    it 'action 必須在允許的列表中' do
      audit_log = AuditLog.new(user: user, action: 'invalid_action')
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:action]).to include('is not included in the list')
    end

    it '允許有效的 action' do
      AuditLog::ACTIONS.each do |action|
        audit_log = AuditLog.new(user: user, action: action)
        expect(audit_log).to be_valid
      end
    end
  end

  describe 'associations' do
    it '屬於 user' do
      audit_log = create(:audit_log, user: user)
      expect(audit_log.user).to eq(user)
    end

    it 'auditable 可以是 nil' do
      audit_log = create(:audit_log, user: user, auditable: nil)
      expect(audit_log).to be_valid
    end
  end

  describe '.log' do
    it '創建審計日誌記錄' do
      expect {
        AuditLog.log(
          user: user,
          action: 'deposit',
          metadata: { amount: 1000 },
          ip_address: '127.0.0.1'
        )
      }.to change(AuditLog, :count).by(1)
    end

    it '記錄所有必要欄位' do
      audit_log = AuditLog.log(
        user: user,
        action: 'deposit',
        metadata: { amount: 1000, description: '測試入金' },
        ip_address: '192.168.1.1'
      )

      expect(audit_log.user).to eq(user)
      expect(audit_log.action).to eq('deposit')
      expect(audit_log.metadata['amount']).to eq(1000)
      expect(audit_log.metadata['description']).to eq('測試入金')
      expect(audit_log.ip_address).to eq('192.168.1.1')
    end

    it '記錄時可以不指定 auditable' do
      audit_log = AuditLog.log(
        user: user,
        action: 'deposit'
      )

      expect(audit_log.auditable).to be_nil
      expect(audit_log.user).to eq(user)
      expect(audit_log.action).to eq('deposit')
    end
  end

  describe 'default_scope' do
    it '按 created_at 降序排列' do
      old_log = create(:audit_log, user: user, created_at: 1.day.ago)
      new_log = create(:audit_log, user: user, created_at: Time.current)

      logs = AuditLog.all
      expect(logs.first).to eq(new_log)
      expect(logs.last).to eq(old_log)
    end
  end
end
