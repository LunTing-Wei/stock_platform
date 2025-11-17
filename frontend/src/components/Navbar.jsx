import { useContext } from 'react'
import { useNavigate } from 'react-router-dom'
import { AuthContext } from '../context/AuthContext'

function Navbar({ showBackButton = false, showLogout = false, title = '' }){
    const navigate = useNavigate()
    const { user, logout} = useContext(AuthContext)

    const handleLogout = async() => {
        await logout()
        navigate('/login')
    }
    if(showLogout){
        return(
            <nav className="bg-white shadow-md">
                <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
                    <h1 className="text-2xl font-bold text-gray-800">
                        股票交易平台
                    </h1>
                    <div className="flex items-center gap-4">
                        <span className="text-gray-600">{user?.email}</span>
                        <button
                          onClick={handleLogout}
                          className="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600"
                        >
                          登出
                        </button>
                    </div>
                </div>
            </nav>
        )
    }

    if(showBackButton){
        return(
            <div className="mb-6">
                <button
                  onClick={() => navigate('/dashboard')}
                  className="text-blue-600 hover:text-blue-800 mb-4">
                  ← 返回首頁
                </button>
                {title && (
                  <h1 className="text-3xl font-bold">{title}</h1>
                )}
            </div>
        )
    }

    return null
}

export default Navbar