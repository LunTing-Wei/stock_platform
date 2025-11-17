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

    useEffect(()=>{
        if(!loading && !user){
          navigate('/login')
        }
    }, [loading, user, navigate])

    useEffect(() => {
        if(user){
          fetchAccount()
        }
    },[user])

    const fetchAccount = async () => {
        try {
            const response = await api.get('/account')
            setAccount(response.data.data.account)
        } catch(error){
            console.error('獲取帳戶失敗:', error)
        }finally{
            setAccountLoading(false)
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
            {account && (
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="bg-blue-50 p-4 rounded">
                  <p className="text-gray-600 text-sm">帳戶餘額</p>
                  <p className="text-2xl font-bold text-blue-600">
                    ${account.balance}
                  </p>
                </div>
                <div className="bg-green-50 p-4 rounded">
                  <p className="text-gray-600 text-sm">可用餘額</p>
                  <p className="text-2xl font-bold text-green-600">
                    ${account.available_balance}
                  </p>
                </div>
                <div className="bg-yellow-50 p-4 rounded">
                  <p className="text-gray-600 text-sm">持倉市值</p>
                  <p className="text-2xl font-bold text-yellow-600">
                    ${account.total_position_value}
                  </p>
                </div>
                <div className="bg-purple-50 p-4 rounded">
                  <p className="text-gray-600 text-sm">總資產</p>
                  <p className="text-2xl font-bold text-purple-600">
                    ${account.total_assets}
                  </p>
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