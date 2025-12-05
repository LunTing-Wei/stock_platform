import { BrowserRouter, Routes, Route, Navigate} from "react-router-dom";
import { AuthProvider } from "./context/AuthContext";
import ErrorBoundary from './components/ErrorBoundary'
import { Toaster } from 'react-hot-toast'
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import Dashboard from './pages/Dashboard';
import OrderPage from './pages/OrderPage';
import PositionsPage from "./pages/PositionsPage";
import TransactionsPage from './pages/TransactionsPage'
import OrdersListPage from './pages/OrdersListPage'


function App() {
  return (
    <ErrorBoundary>
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<Navigate to="/dashboard" />} />
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/orders/new" element={<OrderPage />} />
            <Route path="/orders" element={<OrdersListPage />} />
            <Route path="/positions" element={<PositionsPage />} />
            <Route path="/transactions" element={<TransactionsPage />} />
          </Routes>
        </BrowserRouter>
      </AuthProvider>

      <Toaster
        position="top-right"
        reverseOrder={false}
        toastOptions={{
          duration: 3000,
          style: {
            background: '#363636',
            color: '#fff',
          },
          success: {
            duration: 3000,
            iconTheme: {
              primary: '#10b981',
              secondary: '#fff',
            },
          },
          error: {
            duration: 4000,
            iconTheme: {
              primary: '#ef4444',
              secondary: '#fff',
            },
          },
        }}/>
    </ErrorBoundary>
  )
}

export default App