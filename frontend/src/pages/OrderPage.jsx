import { useState, useContext, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { AuthContext } from '../context/AuthContext';
import api from '../api/client'
import Navbar from '../components/Navbar'

function OrderPage(){
    const {user,loading} = useContext(AuthContext)
    const navigate = useNavigate()

    const [formData, setFormData] = useState({
        symbol:'',
        quantity:'',
        price: '',
        side: 'buy'
    })

    const [submitting, setSubmitting] = useState(false)
    const [error, setError] = useState(null)
    const [validationErrors, setValidationErrors] = useState({})

    useEffect(()=>{
        if(!loading && !user){
            navigate('/login')
        }
    }, [loading,user,navigate])
    const handleChange = (e) => {
        const { name, value } = e.target
        const newValue = name === 'symbol' ? value.toUpperCase() : value
        setFormData({
            ...formData,
            [name]: newValue
        })

        if(validationErrors[name]){
          setValidationErrors({
            ...validationErrors,
            [name]: undefined
          })
        }
    }
    const validateForm = () => {
      const errors = {}

      // ========== 1. 驗證股票代碼 ==========
      const symbol =formData.symbol.trim()
      if(!symbol){
        errors.symbol = '請輸入股票代碼'
      }else if(!/^[A-Z0-9]+$/.test(symbol)){
        errors.symbol = '股票代碼只能包含英文字母和數字'
      }else if(symbol.length > 10){
        errors.symbol = '股票代碼最多 10 個字元'
      }
      // ========== 2. 驗證數量 ==========
      const quantity = formData.quantity
      if(!quantity){
        errors.quantity = '請輸入數量'
      } else if(isNaN(quantity)){
        errors.quantity = '數量必須是數字'
      } else if (Number(quantity) <= 0){
        errors.quantity = '數量必須大於 0'
      } else if(!Number.isInteger(Number(quantity))){
        errors.quantity = '數量必須是整數'
      }
      // ========== 3. 驗證價格 ==========
      const price = formData.price
      if (!price) {
        errors.price = '請輸入價格'
      } else if (isNaN(price)) {
        errors.price = '價格必須是數字'
      } else if (Number(price) <= 0) {
        errors.price = '價格必須大於 0'
      } else if (Number(price) < 0.01) {
        errors.price = '價格最小為 0.01'
      } else {
        const decimalPlaces = (price.toString().split('.')[1] || '').length
        if(decimalPlaces > 2){
          errors.price = '價格最多兩位小數'
        }
      }

      return errors
    }
    const handleSubmit = async (e) =>{
        e.preventDefault()

        const errors = validateForm()
        if(Object.keys(errors).length > 0){
          setValidationErrors(errors)
          return
        }
        setValidationErrors({})

        setSubmitting(true)
        setError(null)

        try{
            const response = await api.post('/orders',{
                order: formData
            })
            console.log('下單成功:', response.data)

            alert('✅ 下單成功!')
            navigate("/positions")
            setFormData({
                symbol: '',
                quantity: '',
                price: '',
                side: 'buy'
            })
        }catch(err){
            console.error('下單失敗:', err)
            setError(err.response?.data?.error || '下單失敗,請稍後再試')
        }finally{
            setSubmitting(false)
        }

    }
    if(loading){
        return(
            <div className="min-h-screen flex items-center justify-center">
                <div className="text-xl">載入中...</div>
            </div>
        )
    }
    return (
    <div className="min-h-screen bg-gray-100">
      <div className="max-w-2xl mx-auto px-4 py-8">
        <Navbar showBackButton={true} title="下單交易" />

        <form onSubmit={handleSubmit} className="bg-white rounded-lg shadow-md p-6">
          {error && (
            <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded">
              <p className="text-red-600">{error}</p>
            </div>
          )}

          <div className="mb-4">
            <label className="block text-gray-700 font-bold mb-2">
              股票代碼
            </label>
            <input
              type="text"
              name="symbol"
              value={formData.symbol}
              onChange={handleChange}
              placeholder="例如: AAPL"
              required
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            {validationErrors.symbol && (
              <p className="mt-1 text-sm text-red-600">
                {validationErrors.symbol}
              </p>
            )}
          </div>

          <div className="mb-4">
            <label className="block text-gray-700 font-bold mb-2">
              交易方向
            </label>
            <div className="flex gap-4">
              <label className="flex items-center">
                <input
                  type="radio"
                  name="side"
                  value="buy"
                  checked={formData.side === 'buy'}
                  onChange={handleChange}
                  className="mr-2"
                />
                買入
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="side"
                  value="sell"
                  checked={formData.side === 'sell'}
                  onChange={handleChange}
                  className="mr-2"
                />
                賣出
              </label>
            </div>
          </div>

          <div className="mb-4">
            <label className="block text-gray-700 font-bold mb-2">
              數量
            </label>
            <input
              type="number"
              name="quantity"
              value={formData.quantity}
              onChange={handleChange}
              placeholder="請輸入數量"
              required
              min="1"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            {validationErrors.quantity && (
              <p className="mt-1 text-sm text-red-600">
                {validationErrors.quantity}
              </p>
            )}
          </div>

          <div className="mb-6">
            <label className="block text-gray-700 font-bold mb-2">
              價格
            </label>
            <input
              type="number"
              name="price"
              value={formData.price}
              onChange={handleChange}
              placeholder="請輸入價格"
              required
              min="0.01"
              step="0.01"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            {validationErrors.price && (
              <p className="mt-1 text-sm text-red-600">
                {validationErrors.price}
              </p>
            )}
          </div>

          <button
            type="submit"
            disabled={submitting}
            className={`w-full py-3 rounded-lg font-bold text-white ${
              submitting
                ? 'bg-gray-400 cursor-not-allowed'
                : 'bg-blue-600 hover:bg-blue-700'
            }`}
          >
            {submitting ? '提交中...' : '確認下單'}
          </button>
        </form>
      </div>
    </div>
  )
}
export default OrderPage