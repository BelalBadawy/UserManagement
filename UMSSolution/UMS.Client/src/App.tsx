import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import LoginLayout from './layouts/LoginLayout'
import Login from './pages/Login'
import Register from './pages/Register'
import ConfirmEmail from './pages/ConfirmEmail'
import ResendConfirmation from './pages/ResendConfirmation'
import ConfirmEmailChange from './pages/ConfirmEmailChange'
import { ToastProvider } from './components/ui/toast'
import './App.css'

function App() {
  return (
    <ToastProvider>
      <BrowserRouter>
        <Routes>
          {/* Auth Group */}
          <Route element={<LoginLayout />}>
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route path="/confirm-email" element={<ConfirmEmail />} />
            <Route path="/resend-confirmation" element={<ResendConfirmation />} />
            <Route path="/confirm-email-change" element={<ConfirmEmailChange />} />
          </Route>

          {/* Catch-all redirect to login */}
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </BrowserRouter>
    </ToastProvider>
  )
}

export default App
