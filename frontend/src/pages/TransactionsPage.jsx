import { useState, useContext, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { AuthContext } from '../context/AuthContext';
import api from '../api/client'
import Navbar from '../components/Navbar'

function TransactionsPage() {
    const { user, loading: authLoading } = useContext(AuthContext)
    const navigate = useNavigate()

    const [transactions, setTransactions] = useState([])
    const [pagination, setPagination] = useState(null)

    const [loading, setLoading] = useState(true)
    const [error, setError] = useState(null)

    useEffect(() => {
      if(!authLoading && !user){
        navigate('/login')
      }
    },[authLoading, user, navigate])

    useEffect(() => {
        if(user){
            fetchTransactions()
        }
    }, [user])

    const fetchTransactions = async () => {
        setLoading(true)
        setError(null)

        try{
            const response = await api.get("/transactions")
            setTransactions(response.data.data.transactions)
            setPagination(response.data.data.pagination)
        }catch(err){
            console.error('取得交易記錄失敗:', err)
            setError(err.response?.data?.error || '取得交易記錄失敗')
        }finally{
            setLoading(false)
        }
    }
    // 格式化日期時間
    const formatDate = (dateString) => {
      const date = new Date(dateString);
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      const hours = String(date.getHours()).padStart(2, '0');
      const minutes = String(date.getMinutes()).padStart(2, '0');

      return `${year}-${month}-${day} ${hours}:${minutes}`;
    }
    // 取得交易類型的中文標籤
    const getTransactionTypeLabel = (type) => {
      const labels = {
        buy: '買入',
        sell: '賣出',
        deposit: '入金',
        withdrawal: '出金',
        fee: '手續費',
        dividend: '股息',
        adjustment: '調整'
      };
      return labels[type] || type;
    }
    // 取得交易類型的顏色
    const getTypeColor = (type) => {
      const colors = {
        buy: 'text-blue-600 bg-blue-50',
        sell: 'text-orange-600 bg-orange-50',
        deposit: 'text-green-600 bg-green-50',
        withdrawal: 'text-red-600 bg-red-50',
        fee: 'text-gray-600 bg-gray-50',
        dividend: 'text-purple-600 bg-purple-50',
        adjustment: 'text-yellow-600 bg-yellow-50'
      };
      return colors[type] || 'text-gray-600 bg-gray-50';
    }

    // 取得金額顏色
    const getAmountColor = (amount) => {
      if (amount > 0) return 'text-green-600';
      if (amount < 0) return 'text-red-600';
      return 'text-gray-600';
    }

    // 安全的數字格式化
    const formatNumber = (value, decimals = 2) => {
      const num = Number(value);
      return isNaN(num) ? '0.00' : num.toFixed(decimals);
    }


    if(authLoading || loading){
        return(
            <div className="min-h-screen flex items-center justify-center">
                <div className="text-xl">載入中...</div>
            </div>
        )
    }

    return(
      <div className="min-h-screen bg-gray-100">
        <div className="max-w-6xl mx-auto px-4 py-8">
          <Navbar showBackButton={true} title="交易記錄" />

          {/* 錯誤訊息 */}
          {error && (
            <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded">
              <p className="text-red-600">{error}</p>
            </div>
          )}

          {/* 交易記錄列表  */}
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-bold mb-4">交易明細</h2>
            {transactions.length > 0 ? (
                <div className="overflow-x-auto">
                    <table className="w-full">
                        <thead>
                            <tr className="border-b">
                                <th className="text-left py-3 px-4">時間</th>
                                <th className="text-left py-3 px-4">類型</th>
                                <th className="text-left py-3 px-4">說明</th>
                                <th className="text-right py-3 px-4">金額</th>
                                <th className="text-right py-3 px-4">餘額</th>
                            </tr>
                        </thead>
                        <tbody>
                            {transactions.map((transaction) => (
                              <tr key={transaction.id} className="border-b hover:bg-gray-50">
                                {/* 時間 */}
                                <td className="py-3 px-4 text-gray-600">
                                    {formatDate(transaction.created_at)}
                                </td>

                                {/* 類型 */}
                                <td className="py-3 px-4">
                                  <span className={`px-2 py-1 rounded text-sm font-bold ${getTypeColor(transaction.transaction_type)}`}>
                                    {getTransactionTypeLabel(transaction.transaction_type)}
                                  </span>
                                </td>

                                {/* 說明 */}
                                <td className="py-3 px-4 text-gray-700">
                                    {transaction.description}
                                </td>

                                {/* 金額 */}
                                <td className={`text-right py-3 px-4 font-bold ${getAmountColor(transaction.amount)}`}>
                                    {transaction.amount > 0 && '+'}${formatNumber(Math.abs(transaction.amount))}
                                </td>

                                {/* 餘額 */}
                                <td className="text-right py-3 px-4 text-gray-700">
                                    ${formatNumber(transaction.balance_after)}
                                </td>
                              </tr>
                            ))}
                        </tbody>
                    </table>

                    {/* 分頁資訊 */}
                    {pagination && (
                        <div className="mt-4 text-center text-gray-600">
                            第 {pagination.current_page} 頁 / 共 {pagination.total} 筆記錄
                        </div>
                    )}
                </div>
            ) : (
                <div className="text-center py-12">
                    <p className="text-gray-500 text-lg mb-4">目前沒有任何交易記錄</p>
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

export default TransactionsPage