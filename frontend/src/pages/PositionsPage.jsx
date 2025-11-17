import { useState, useContext, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { AuthContext } from '../context/AuthContext';
import api from '../api/client'
import Navbar from '../components/Navbar'

function PositionsPage() {
    const { user, loading: authLoading } = useContext(AuthContext)
    const navigate = useNavigate()

    const [positions, setPositions] = useState([])
    const [summary, setSummary] = useState(null)

    const [loading, setLoading] = useState(true)
    const [error, setError] = useState(null)

    useEffect(() =>{
        if(!authLoading && !user){
            navigate('/login')
        }
    }, [authLoading, user, navigate])

    useEffect(() => {
        if(user){
          fetchPositions()
        }
    },[user])

    const fetchPositions = async () => {
        setLoading(true)
        setError(null)

        try{
            const response = await api.get('/positions')
            setPositions(response.data.data.positions)
            setSummary(response.data.data.summary)
        }catch(err){
            console.error('取得持倉失敗:', err)
            setError(err.response?.data?.error || '取得持倉失敗')
        }finally{
            setLoading(false)
        }
    }
    const getProfitColor = (value) => {
        if (value > 0) return 'text-green-600'
        if (value < 0) return 'text-red-600'
        return 'text-gray-600'
    }
    const getProfitBgColor = (value) =>{
        if (value > 0) return 'bg-green-50'
        if (value < 0) return 'bg-red-50'
        return 'bg-gray-50'
    }
    const formatNumber = (value, decimals = 2) => {
      const num = Number(value);
      return isNaN(num) ? '0.00' : num.toFixed(decimals);
    };

    if(authLoading || loading){
        return(
            <div className="min-h-screen flex items-center justify-center">
              <div className="text-xl">載入中...</div>
            </div>
        )
    }
    return (
        <div className="min-h-screen bg-gray-100">
        <div className="max-w-6xl mx-auto px-4 py-8">
          <Navbar showBackButton={true} title="我的持倉" />

          {/* 錯誤訊息 */}
          {error && (
            <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded">
              <p className="text-red-600">{error}</p>
            </div>
          )}

          {/* 彙總資訊 */}
          {summary && (
            <div className="bg-white rounded-lg shadow-md p-6 mb-6">
                <h2 className="text-xl font-bold mb-4">持倉總覽</h2>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  
                  <div className="bg-blue-50 p-4 rounded">
                    <p className="text-gray-600 text-sm">總持倉數</p>
                    <p className="text-2xl font-bold text-blue-600">
                      {summary.total_positions}
                     </p>
                  </div>
                  
                  <div className="bg-purple-50 p-4 rounded">
                    <p className="text-gray-600 text-sm">總市值</p>
                    <p className="text-2xl font-bold text-purple-600">
                      ${formatNumber(summary.total_market_value)}
                    </p>
                  </div>

                  <div className="bg-yellow-50 p-4 rounded">
                    <p className="text-gray-600 text-sm">總成本</p>
                    <p className="text-2xl font-bold text-yellow-600">
                        ${formatNumber(summary.total_cost_basis)}
                    </p>
                  </div>

                  <div className={`p-4 rounded ${getProfitBgColor(summary.total_profit_loss)}`}>
                    <p className="text-gray-600 text-sm">總損益</p>
                    <p className={`text-2xl font-bold ${getProfitColor(summary.total_profit_loss)}`}>
                      {summary.total_profit_loss > 0 && '+'}${formatNumber(summary.total_profit_loss)}
                      <span className="text-sm ml-2">
                        ({summary.total_profit_loss > 0 && '+'}
                        {formatNumber(summary.total_profit_loss_percentage)}%)
                      </span>
                    </p>
                  </div>
                </div>
            </div>
          )}
          {/* 持倉列表 */}
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-bold mb-4">持倉明細</h2>

            {positions.length > 0 ? (
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b">
                        <th className="text-left py-3 px-4">股票代碼</th>
                        <th className="text-right py-3 px-4">持有數量</th>
                        <th className="text-right py-3 px-4">平均成本</th>
                        <th className="text-right py-3 px-4">當前價格</th>
                        <th className="text-right py-3 px-4">市值</th>
                        <th className="text-right py-3 px-4">成本</th>
                        <th className="text-right py-3 px-4">損益</th>
                        <th className="text-right py-3 px-4">損益率</th>
                    </tr>
                  </thead>
                  <tbody>
                    {positions.map((position) => (
                        <tr key={position.id} className="border-b hover:bg-gray-50">
                            <td className="py-3 px-4 font-bold">{position.symbol}</td>
                            <td className="text-right py-3 px-4">{position.quantity}</td>
                            <td className="text-right py-3 px-4">${formatNumber(position.average_cost)}</td>
                            <td className="text-right py-3 px-4">${formatNumber(position.current_price)}</td>
                            <td className="text-right py-3 px-4">${formatNumber(position.market_value)}</td>
                            <td className="text-right py-3 px-4">${formatNumber(position.cost_basis)}</td>
                            <td className={`text-right py-3 px-4 font-bold ${getProfitColor(position.profit_loss)}`}>
                                 {position.profit_loss > 0 && '+'}${formatNumber(position.profit_loss)}
                            </td>
                            <td className={`text-right py-3 px-4 font-bold ${getProfitColor(position.profit_loss)}`}>
                                {position.profit_loss_percentage > 0 && '+'}
                                {formatNumber(position.profit_loss_percentage)}%
                            </td>
                        </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="text-center py-12">
                <p className="text-gray-500 text-lg mb-4">目前沒有任何持倉</p>
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

export default PositionsPage