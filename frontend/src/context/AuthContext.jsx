import { createContext,useState, useEffect } from "react";
import api from '../api/client'

export const AuthContext = createContext()

export const AuthProvider = ({children}) => {
    const [user, setUser] = useState(null)
    const [loading, setLoading] = useState(true)

    useEffect(() => {
        checkAuth()

        const handleLogout = () => {
            setUser(null)
        }

        window.addEventListener('auth:logout', handleLogout)
        return () => {
            window.removeEventListener('auth:logout', handleLogout)
        }
    }, [])

    const checkAuth = async () => {
      try {
        const response = await api.get('/account')
        setUser(response.data.data.user || {authenticated: true})
      }catch(error) {
        if(error.response?.status === 401){
            setUser(null)
        }
      }finally{
        setLoading(false)
      }
    }
    const login = async(email, password) => {
        const response = await api.post('/sessions/sign_in',{
            user: { email, password }
        })
        setUser(response.data.data.user)
        return response
    }

    const register = async(email, password, passwordConfirmation) =>{
        const response = await api.post('/sessions/sign_up',{
            user:{
                email,
                password,
                password_confirmation:passwordConfirmation
            }
        })
        setUser(response.data.data.user)
        return response
    }
    const logout = async() => {
        try{
            await api.delete('/sessions/sign_out')
        }catch(error){
            console.error('Logout API failed:', error)
        }finally{
            setUser(null)
        }
    }
    // 簡寫 (ES6)
    const value = {
        user,
        loading,
        login,
        register,
        logout,
        checkAuth,
    }
    return (
        <AuthContext.Provider value={value}>
            {children}
        </AuthContext.Provider>
    )
}

