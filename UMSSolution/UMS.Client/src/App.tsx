import { BrowserRouter, Routes, Route, Navigate, Outlet } from 'react-router-dom'
import LoginLayout from './layouts/LoginLayout'
import Login from './pages/Login'
import Register from './pages/Register'
import ConfirmEmail from './pages/ConfirmEmail'
import ResendConfirmation from './pages/ResendConfirmation'
import ConfirmEmailChange from './pages/ConfirmEmailChange'
import ForgotPassword from './pages/ForgotPassword'
import ResetPassword from './pages/ResetPassword'
import AdminHome from './pages/AdminHome'
import PublicHome from './pages/PublicHome'
import Profile from './pages/Profile'
import { ToastProvider } from './components/ui/toast'
import { AuthProvider, useAuth } from './components/AuthContext'
import { ProtectedRoute } from './components/ProtectedRoute'
import './App.css'

// Helper component to redirect authenticated users away from Auth pages
function PublicOnlyRoute() {
  const { isAuthenticated, user } = useAuth()

  if (isAuthenticated && user) {
    const isAdmin = user.roles.includes('Admin')
    return <Navigate to={isAdmin ? '/admin' : '/'} replace />
  }

  return <Outlet />
}

function AppContent() {
  return (
    <Routes>
      {/* Public Home Page - Open to all */}
      <Route path="/" element={<PublicHome />} />

      {/* Guest/Auth Only Group (Login, Register, etc.) */}
      <Route element={<PublicOnlyRoute />}>
        <Route element={<LoginLayout />}>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/confirm-email" element={<ConfirmEmail />} />
          <Route path="/resend-confirmation" element={<ResendConfirmation />} />
          <Route path="/confirm-email-change" element={<ConfirmEmailChange />} />
          <Route path="/forgot-password" element={<ForgotPassword />} />
          <Route path="/reset-password" element={<ResetPassword />} />
        </Route>
      </Route>

      {/* Authenticated Route Group - Protected for all authenticated users */}
      <Route element={<ProtectedRoute />}>
        <Route path="/profile" element={<Profile />} />
      </Route>

      {/* Admin Route Group - Protected & requires Admin role */}
      <Route element={<ProtectedRoute allowedRoles={['Admin']} />}>
        <Route path="/admin" element={<AdminHome />} />
      </Route>

      {/* Catch-all redirect */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

function App() {
  return (
    <ToastProvider>
      <AuthProvider>
        <BrowserRouter>
          <AppContent />
        </BrowserRouter>
      </AuthProvider>
    </ToastProvider>
  )
}

export default App
