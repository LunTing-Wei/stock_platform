import { useState, useContext, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { AuthContext } from '../context/AuthContext';
import api from '../api/client'
import Navbar from '../components/Navbar'
import toast from 'react-hot-toast'

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

    const [account, setAccount] = useState(null)
    const [positions, setPositions] = useState([])
    const [accountLoading, setAccountLoading] = useState(true)

    const [stockPriceData,setStockPriceData] = useState(null)
    const [fetchingPrice, setFetchingPrice] = useState(false)

    useEffect(()=>{
        if(!loading && !user){
            navigate('/login')
        }
    }, [loading,user,navigate])

    useEffect(() => {
      if(user){
        fetchAccountAndPositions()
      }
    },[user])

    const handleChange = (e) => {
        const { name, value } = e.target
        const newValue = value
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
        if(name === "symbol"){
          setStockPriceData(null)
        }
    }

    const fetchAccountAndPositions = async () =>{
      setAccountLoading(true)
      try{
        const [accountRes, positionsRes] = await Promise.all([
            api.get('/account'),
            api.get('/positions')
        ])

        setAccount(accountRes.data.data.account)
        setPositions(positionsRes.data.data.positions || [])
      } catch(err) {
        console.error('取得資料失敗:', err)

        setAccount(null)
        setPositions([])
      } finally {
        setAccountLoading(false)
      }
    }

    const fetchStockPrice = async () => {
      if(!formData.symbol.trim()){
        toast.error('請先輸入股票代碼', { icon: '⚠️' })
        return
      }

      setFetchingPrice(true)
      setStockPriceData(null)

      try{
        const response = await api.get(`/stock_prices/${formData.symbol}`)
        const data = response.data.data

        setStockPriceData(data)
        setFormData({
          ...formData,
          price: data.price.toString()
        })

        toast.success(`已查詢到 ${formData.symbol} 的股價`, { icon: '📈' })
      }catch(err){
        const errorData = err.response?.data?.error
        const errorMessage = typeof errorData === 'string'
          ? errorData
          : errorData?.message || "查詢股價失敗"
        toast.error(errorMessage, { icon: '❌' })
      }finally{
        setFetchingPrice(false)
      }
    }

    const calculateTotalAmount = () => {
      const qty =  Number(formData.quantity)
      const price = Number(formData.price)

      if (isNaN(qty) || isNaN(price) || qty <= 0 || price <= 0){
        return 0
      }
      return qty * price
    }

    const checkBalance = () => {
      if (formData.side !== 'buy') return { sufficient: true }
      if (!account) return { sufficient: true, loading: true }

      const totalAmount = calculateTotalAmount()
      if (totalAmount === 0) return { sufficient: true }

      const availableBalance = Number(account.balance || 0)
      const sufficient = availableBalance >= totalAmount
      const shortage = sufficient ? 0 : totalAmount - availableBalance

      return {
        sufficient,
        availableBalance,
        totalAmount,
        shortage
      }
    }

    const checkPosition = () => {
      if (formData.side !== 'sell') return { sufficient: true }
      if (!formData.symbol) return { sufficient: true }

      const qty = Number(formData.quantity)
      if (isNaN(qty) || qty <= 0) return { sufficient: true }

      const position = positions.find( p => p.symbol === formData.symbol.toUpperCase())
      const availableQty = position ? position.quantity : 0
      const sufficient = availableQty >= qty
      const shortage = sufficient ? 0 : qty - availableQty
      return {
        sufficient,
        availableQty,
        requestedQty: qty,
        shortage
      }
    }

    const validateForm = () => {
      const errors = {}

      // ========== 1. 驗證股票代碼 ==========
      const symbol =formData.symbol.trim()
      if(!symbol){
        errors.symbol = '請輸入股票代碼'
      }else if(!/^[0-9]{4,6}$/.test(symbol)){
        errors.symbol = '股票代碼格式錯誤(應為4-6位數字)'
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

            toast.success('下單成功！',{icon: '✅',})
            navigate("/positions")
            setFormData({
                symbol: '',
                quantity: '',
                price: '',
                side: 'buy'
            })
            setStockPriceData(null)
        }catch(err){
            console.error('下單失敗:', err)
            const errorData = err.response?.data?.error
            const errorMessage = typeof errorData === 'string'
              ? errorData
              : errorData?.message || '下單失敗，請稍後再試'
            setError(errorMessage)
            toast.error(errorMessage,{icon:'❌'})
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
    const balanceCheck = formData.side === 'buy' ? checkBalance() : { sufficient: true }
    const positionCheck = formData.side === 'sell' ? checkPosition() : { sufficient: true }
    const isDisabled =
      submitting ||
      !balanceCheck.sufficient ||
      !positionCheck.sufficient

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

            <div className="flex gap-2 items-end">
              <div className="flex-1">
                <input 
                  type="text"
                  name="symbol"
                  value={formData.symbol}
                  onChange={handleChange}
                  placeholder="例如: 2330"
                  required
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
                  {validationErrors.symbol && (
                    <p className="mt-1 text-sm text-red-600">
                      {validationErrors.symbol}
                    </p>
                  )}
              </div>

              <button
                type="button"
                onClick={fetchStockPrice}
                disabled={fetchingPrice || !formData.symbol.trim()}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors">
                  {fetchingPrice ? '查詢中...' : '查詢股價'}
              </button>
            </div>

            {stockPriceData && (
              <div className="mt-2 p-3 bg-blue-50 border border-blue-200 rounded-lg">
                <p className="text-sm text-gray-700">
                  <span className="font-medium">{stockPriceData.symbol}</span>收盤價：
                  <span className="text-lg font-bold text-blue-600 ml-2">
                    ${stockPriceData.price.toFixed(2)}
                  </span>
                  <span className="text-xs text-gray-500 ml-2">
                    ({stockPriceData.date})
                  </span>
                </p>
              </div>
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

          {formData.quantity && formData.price && (
            <div className="mb-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <div className="flex justify-between items-center"> 
                <span className="text-gray-700 font-medium">總金額:</span>
                <span className="text-xl font-bold text-blue-600">
                  ${calculateTotalAmount().toFixed(2)}
                </span>
              </div>
            </div>
          )}

          {formData.side === 'buy' && formData.quantity && formData.price && !accountLoading && (
            <div className={`mb-4 p-4 rounded-lg border ${
              checkBalance().sufficient
                ? 'bg-green-50 border-green-200'
                :'bg-red-50 border-red-200'
            }`}> 
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-gray-700">可用餘額:</span>
                  <span className="font-semibold">
                    ${(checkBalance().availableBalance || 0).toFixed(2)}
                  </span>
                </div>

                {!checkBalance().sufficient && (
                  <div className="flex items-start gap-2 mt-2 pt-2 border-t border-red-300">
                    <svg className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <div className="flex-1">
                       <p className="text-red-800 font-semibold text-sm">餘額不足</p>
                       <p className="text-red-700 text-sm">
                         還需要 ${checkBalance().shortage.toFixed(2)}
                       </p>
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}

          {formData.side === 'sell' && formData.symbol && formData.quantity && !accountLoading && (
            <div className={`mb-4 p-4 rounded-lg border ${
              checkPosition().sufficient
                ? 'bg-green-50 border-green-200'
                :'bg-red-50 border-red-200'
            }`}>
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-gray-700">持有數量:</span>
                  <span className="font-semibold">
                    {checkPosition().availableQty || 0} 股
                  </span>
                </div>

                {!checkPosition().sufficient && (
                  <div className="flex items-start gap-2 mt-2 pt-2 border-t border-red-300">
                    <svg className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>

                    <div className="flex-1">
                      <p className="text-red-800 font-semibold text-sm">持倉不足</p>
                      <p className="text-red-700 text-sm">
                        還缺少 {checkPosition().shortage} 股
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}

          <button
            type="submit"
            disabled={isDisabled}
            className={`w-full py-3 rounded-lg font-bold text-white ${
              isDisabled
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