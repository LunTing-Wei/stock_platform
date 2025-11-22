import { useContext, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { AuthContext } from '../context/AuthContext';
import api from '../api/client';
import Navbar from '../components/Navbar'

function Dashboard() {
    const { user, loading, logout } = useContext(AuthContext);
    const navigate = useNavigate();
    const [account, setAccount] = useState(null);
    const [accountLoading, setAccountLoading] = useState(true);
    const [accountError, setAccountError] = useState(null)
    const [positionsSummary, setPositionsSummary] = useState(null)

    useEffect(()=>{
        if(!loading && !user){
          navigate('/login')
        }
    }, [loading, user, navigate])

    useEffect(() => {
        if(user){
          fetchAccount()
          fetchPositions()
        }
    },[user])

    const formatCurrency = (value) => {
      const num = Number(value)
      if (isNaN(num)) return '0.00'
      return num.toFixed(2)
    }

    const fetchAccount = async () => {
      setAccountLoading(true)
      setAccountError(null)
      try {
          const response = await api.get('/account')
          setAccount(response.data.data.account)
      } catch(error){
          console.error('獲取帳戶失敗:', error)
          setAccountError(error.response?.data?.error || '無法載入帳戶資訊，請稍後再試')
      }finally{
          setAccountLoading(false)
      }
    }

    const fetchPositions = async () => {
      try{
        const response = await api.get('/positions')
        setPositionsSummary(response.data.data.summary)
      }catch(err){
        console.error('獲取持倉失敗:', err)
        setPositionsSummary({
          total_profit_loss: 0,
          total_profit_loss_percentage: 0
        })
      }
    }
    if(loading || accountLoading){
        return(
            <div className="min-h-screen flex items-center justify-center">
                <div className="text-xl">載入中...</div>
            </div>
        )
    }

    return(
      <div className="min-h-screen bg-gray-100">
        {/* 導航列 */}
        <Navbar showLogout={true} />

        {/* 主要內容 */}
        <div className="max-w-7xl mx-auto px-4 py-8">
          <div className="bg-white rounded-lg shadow-md p-6 mb-6">
            <h2 className="text-2xl font-bold mb-4">帳戶總覽</h2>
            {accountError && (
              <div className="bg-red-50 border border-red-200 rounded-lg p-6">
                <div className="flex items-start gap-3">
                  <svg
                    className="w-6 h-6 text-red-600 flex-shrink-0 mt-0.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24">
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                  </svg>
                  <div className="flex-1">
                    <h3 className="font-semibold text-red-800 mb-1">載入失敗</h3>
                    <p className="text-red-700 text-sm mb-3">{accountError}</p>
                    <button
                      onClick={fetchAccount}
                      className="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition text-sm font-medium">
                        重新載入
                    </button>
                  </div>
                </div>
              </div>
            )}

            {account && (
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="bg-blue-50 p-4 rounded">
                  <p className="text-gray-600 text-sm">帳戶餘額</p>
                  <p className="text-2xl font-bold text-blue-600">
                    ${formatCurrency(account.balance)}
                  </p>
                </div>
                <div className="bg-yellow-50 p-4 rounded">
                  <p className="text-gray-600 text-sm">持倉市值</p>
                  <p className="text-2xl font-bold text-yellow-600">
                    ${formatCurrency(account.total_position_value)}
                  </p>
                </div>
                <div className="bg-purple-50 p-4 rounded">
                  <p className="text-gray-600 text-sm">總資產</p>
                  <p className="text-2xl font-bold text-purple-600">
                    ${formatCurrency(account.total_assets)}
                  </p>
                </div>
                <div className="bg-gray-50 p-4 rounded">
                  <p className="text-gray-600 text-sm">未實現損益</p>
                  {positionsSummary ? (
                    <div>
                      <p className={`text-2xl font-bold ${
                        positionsSummary.total_profit_loss >= 0
                          ? 'text-green-600'
                          : 'text-red-600'
                      }`}>
                        {positionsSummary.total_profit_loss >= 0 ? '+' : ''}
                        ${formatCurrency(positionsSummary.total_profit_loss)}
                      </p>
                      <p className={`text-sm ${
                        positionsSummary.total_profit_loss_percentage >= 0
                          ? 'text-green-600'
                          : 'text-red-600'
                      }`}>
                        {positionsSummary.total_profit_loss_percentage >= 0 ? '+' : ''}
                        {positionsSummary.total_profit_loss_percentage}%
                      </p>
                    </div>
                  ) : (
                     <p className="text-2xl font-bold text-gray-400">載入中...</p>
                  )}
                </div>
              </div>
            )}
          </div>

          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-2xl font-bold mb-4">快速操作</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <button 
                onClick={() => navigate('/orders/new')}
                className="bg-blue-500 text-white p-4 rounded-lg hover:bg-blue-600">
                下單交易
              </button>
              <button
                onClick={() => navigate('/positions')} 
                className="bg-green-500 text-white p-4 rounded-lg hover:bg-green-600">
                查看持倉
              </button>
              <button
                onClick={() => navigate('/transactions')}
                className="bg-purple-500 text-white p-4 rounded-lg hover:bg-purple-600">
                交易記錄
              </button>
            </div>
          </div>
        </div>
      </div>
    )
}
export default Dashboard