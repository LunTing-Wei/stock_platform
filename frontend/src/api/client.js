import axios from "axios";

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api'
const client = axios.create({
    baseURL: API_URL,
    withCredentials: true,
    headers: {
        'Content-Type': 'application/json',
    }
})

client.interceptors.response.use(
    (response) => response,
    (error) => {
        if(error.response?.status === 401){
            window.dispatchEvent(new Event('auth:logout'))
        }
        return Promise.reject(error)
    }
)

export default client;