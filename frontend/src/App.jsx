import { BrowserRouter, Routes, Route, Navigate} from "react-router-dom";
import { AuthProvider } from "./context/AuthContext";
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import Dashboard from './pages/Dashboard';
import OrderPage from './pages/OrderPage';
import PositionsPage from "./pages/PositionsPage";
import TransactionsPage from './pages/TransactionsPage'

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
           <Route path="/" element={<Navigate to="/dashboard" />} />
           <Route path="/login" element={<LoginPage />} />
           <Route path="/register" element={<RegisterPage />} />
           <Route path="/dashboard" element={<Dashboard />} />
           <Route path="/orders/new" element={<OrderPage />} />
           <Route path="/positions" element={<PositionsPage />} />
           <Route path="/transactions" element={<TransactionsPage />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}

export default App