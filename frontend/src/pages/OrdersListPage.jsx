import { useState, useContext, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { AuthContext } from '../context/AuthContext'
import api from '../api/client'
import Navbar from '../components/Navbar'
import toast from 'react-hot-toast'

function OrdersListPage() {
    const { user, loading: authLoading } = useContext(AuthContext)
    const navigate = useNavigate()

    const [orders, setOrders] = useState([])
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState(null)
    const [cancellingOrderId, setCancellingOrderId] = useState(null)

    const [filterStatus, setFilterStatus] = useState('all')
    const [filterSymbol, setFilterSymbol] = useState('')

    useEffect(() => {
        if(!authLoading && !user){
            navigate('/login')
        }
    }, [authLoading, user, navigate])

    useEffect(() => {
        if(user){
            fetchOrders()
        }
    }, [user, filterStatus, filterSymbol])

    const fetchOrders  = async () => {
        setLoading(true)
        setError(null)

        try{
            const params = {}
            if (filterStatus !== 'all') params.status = filterStatus
            if (filterSymbol) params.symbol = filterSymbol.toUpperCase()
            
            const response = await api.get('/orders', { params })
            setOrders(response.data.data.orders || [])
        }catch(error){
            console.error('獲取訂單失敗:', error)
            setError('無法載入訂單列表')
        }finally{
            setLoading(false)
        }
    }

    const handleCancelOrder = async (orderId) => {
        if (!confirm('確定要取消這筆訂單嗎?')) return

        setCancellingOrderId(orderId)
        try{
            await api.patch(`/orders/${orderId}/cancel`)
            toast.success('訂單已取消', { icon: '✅' })
            fetchOrders()
        }catch(error){
            console.error('取消訂單失敗:', error)
            const errorMsg = error.response?.data?.error || '取消訂單失敗'
            toast.error(errorMsg, { icon: '❌' })
        }finally{
            setCancellingOrderId(null)
        }
    }

    const formatDate = (dateString) => {
      const date = new Date(dateString)
      const year = date.getFullYear()
      const month = String(date.getMonth() + 1).padStart(2, '0')
      const day = String(date.getDate()).padStart(2, '0')
      const hours = String(date.getHours()).padStart(2, '0')
      const minutes = String(date.getMinutes()).padStart(2, '0')
      return `${year}-${month}-${day} ${hours}:${minutes}`
    }

    const getStatusLabel = (status) => {
        const labels = {
            pending: '待成交',
            completed: '已成交',
            cancelled: '已取消'
        }
        return labels[status] || status
    }
    const getStatusColor = (status) => {
        const colors = {
            pending: 'bg-yellow-100 text-yellow-800',
            completed: 'bg-green-100 text-green-800',
            cancelled: 'bg-gray-100 text-gray-800'
        }
        return colors[status] ||'bg-gray-100 text-gray-800'
    }

    const getSideLabel = (side) => {
      return side === 'buy' ? '買入' : '賣出'
    }

    const getSideColor = (side) => {
      return side === 'buy' ? 'text-blue-600' : 'text-orange-600'
    }

    if(authLoading || loading){
        return(
            <div className='min-h-screen flex items-center justify-center'>
                <div className="text-xl">載入中...</div>
            </div>
        )
    }

    return(
        <div className="min-h-screen bg-gray-100">
            <div className="max-w-7xl mx-auto px-4 py-8">
                <Navbar showBackButton={true} title="訂單列表" />

                {error && (
                  <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg">
                    <p className="text-red-600">{error}</p>
                  </div>
                )}

                <div className="bg-white rounded-lg shadow-md p-4 mb-4">
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                訂單狀態
                            </label>
                            <select
                              value={filterStatus}
                              onChange={(e) => setFilterStatus(e.target.value)}
                              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
                                <option value="all">全部</option>
                                <option value="pending">待成交</option>
                                <option value="completed">已成交</option>
                                <option value="cancelled">已取消</option>
                            </select>
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                股票代碼
                            </label>

                            <input
                              type="text"
                              value={filterSymbol}
                              onChange={(e) => setFilterSymbol(e.target.value)}
                              placeholder="例如: 2330"
                              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"/>
                        </div>

                        <div className="flex items-end">
                            <button
                              onClick={() => navigate('/orders/new')}
                              className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition">
                                ➕ 新增訂單
                            </button>
                        </div>
                    </div>
                </div>
                <div className="bg-white rounded-lg shadow-md overflow-hidden">
                    {orders.length > 0 ? (
                        <div className="overflow-x-auto">
                            <table className="w-full">
                                <thead className="bg-gray-50">
                                    <tr>
                                        <th className="text-left py-3 px-4 font-semibold text-gray-700">時間</th>
                                        <th className="text-left py-3 px-4 font-semibold text-gray-700">股票</th>
                                        <th className="text-left py-3 px-4 font-semibold text-gray-700">方向</th>
                                        <th className="text-right py-3 px-4 font-semibold text-gray-700">數量</th>
                                        <th className="text-right py-3 px-4 font-semibold text-gray-700">價格</th>
                                        <th className="text-right py-3 px-4 font-semibold text-gray-700">總額</th>
                                        <th className="text-center py-3 px-4 font-semibold text-gray-700">狀態</th>
                                        <th className="text-center py-3 px-4 font-semibold text-gray-700">操作</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {orders.map((order) => (
                                        <tr key={order.id} className="border-t hover:bg-gray-50">
                                            {/* 時間 */}
                                            <td className="py-3 px-4 text-sm text-gray-600">
                                              {formatDate(order.created_at)}
                                            </td>
                                            {/* 股票代碼 */}
                                            <td className="py-3 px-4">
                                                <span className="font-semibold text-gray-800">
                                                    {order.symbol}
                                                </span>
                                            </td>

                                            {/* 交易方向 */}
                                            <td className="py-3 px-4">
                                                <span className={`font-semibold ${getSideColor(order.side)}`}>
                                                    {getSideLabel(order.side)}
                                                </span>
                                            </td>

                                            {/* 數量 */}
                                            <td className="text-right py-3 px-4 text-gray-800">
                                                {order.quantity}
                                            </td>

                                            {/* 價格 */}
                                            <td className="text-right py-3 px-4 text-gray-800">
                                                ${Number(order.price).toFixed(2)}
                                            </td>

                                            {/* 總額 */}
                                            <td className="text-right py-3 px-4 font-semibold text-gray-800">
                                                ${(order.quantity * Number(order.price)).toFixed(2)}
                                            </td>

                                            {/* 狀態 */}
                                            <td className="text-center py-3 px-4">
                                                <span className={`px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(order.status)}`}>
                                                    {getStatusLabel(order.status)}
                                                </span>
                                            </td>

                                            {/* 操作 */}
                                            <td className="text-center py-3 px-4">
                                                {order.status === 'pending' &&(
                                                    <button
                                                      onClick={() => handleCancelOrder(order.id)}
                                                      disabled={cancellingOrderId === order.id}
                                                      className="px-3 py-1 text-sm bg-red-100 text-red-700 rounded hover:bg-red-200 disabled:bg-gray-200 disabled:text-gray-500 disabled:cursor-not-allowed transition">
                                                        {cancellingOrderId === order.id ? '取消中...' : '取消訂單'}
                                                    </button>
                                                )}
                                                {order.status === 'completed' && (
                                                    <span className="text-sm text-gray-400">已成交</span>
                                                )}
                                                {order.status === 'cancelled' && (
                                                    <span className="text-sm text-gray-400">已取消</span>
                                                )}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    ) : (
                        <div className="text-center py-12">
                            <p className="text-gray-500 text-lg mb-4">目前沒有訂單</p>
                            <button
                              onClick={() => navigate('/orders/new')}
                              className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700">
                                立即下單
                            </button>
                        </div>
                    )}
                </div>
            </div>
        </div>
    )
}

export default OrdersListPage