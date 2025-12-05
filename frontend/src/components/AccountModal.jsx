import {useState} from 'react'
import toast from 'react-hot-toast'

function AccountModal({
  isOpen,
  onClose,
  type, // 'deposit' 或 'withdraw'
  currentBalance,
  onSuccess
}){
  const [amount, setAmount] = useState('')
  const [loading, setLoading] = useState(false)

  const config = {
    deposit: {
        title: '存款',
        buttonText: '確認存款',
        buttonColor: 'bg-green-600 hover:bg-green-700',
        icon: '💰'
    },
    withdraw: {
        title: '提款',
        buttonText: '確認提款',
        buttonColor: 'bg-yellow-600 hover:bg-yellow-700',
        icon: '💸'
    }
  }

  const currentConfig = config[type]

  const validateAmount = () => {
    const num = Number(amount)

    if(!amount || isNaN(num)){
        toast.error('請輸入有效金額')
        return false
    }

    if(num <= 0){
        toast.error('金額必須大於 0')
        return false
    }

    if (num > 1000000) {
        toast.error('單筆金額不得超過 1,000,000')
        return false
    }

    // 提款特殊驗證
    if (type === 'withdraw' && num > currentBalance) {
        toast.error('餘額不足')
        return false
    }

    return true
  }

  const handleSubmit = async (e) => {
    e.preventDefault()

    if(!validateAmount()) return

    setLoading(true)

    try{
        await onSuccess(Number(amount))
        setAmount('')
        onClose()
    }catch(error){
    }finally{
        setLoading(false)
    }
  }

  if(!isOpen) return null

  return(
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div className="bg-white rounded-lg p-6 w-full max-w-md mx-4">
            <div className="flex items-center justify-between mb-4">
                <h2 className="text-2xl font-bold flex items-center gap-2">
                    <span>{currentConfig.icon}</span>
                    <span>{currentConfig.title}</span>
                </h2>
                <button
                  onClick={onClose}
                  className="text-gray-400 hover:text-gray-600 text-2xl">
                    x
                </button>
            </div>

            {type === 'withdraw' && (
                <div className="mb-4 p-3 bg-gray-50 rounded-lg">
                    <p className="text-sm text-gray-600">可用餘額</p>
                    <p className="text-xl font-bold text-gray-800">
                        ${currentBalance.toFixed(2)}
                    </p>
                </div>
            )}

            <form onSubmit={handleSubmit}>
                <div className="mb-4">
                    <label className="block text-gray-700 font-bold mb-2">
                        金額
                    </label>
                    <input
                      type="number"
                      value={amount}
                      onChange={(e) => setAmount(e.target.value)}
                      placeholder="請輸入金額"
                      min="0.01"
                      step="0.01"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      authFocus/>
                </div>

                <div className="flex gap-3">
                    <button
                      type="button"
                      onClick={onClose}
                      className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition">
                        取消
                    </button>
                    <button
                      type="submit"
                      disabled={loading}
                      className={`flex-1 px-4 py-2 text-white rounded-lg transition ${currentConfig.buttonColor} disabled:bg-gray-400 disabled:cursor-not-allowed`}>
                        {loading ? '處理中...' : currentConfig.buttonText}
                    </button>
                </div>
            </form>
        </div>
    </div>
  )
}

export default AccountModal