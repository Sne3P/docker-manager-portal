import { useState } from 'react';
import { useRouter } from 'next/router';
import { useAuth } from '../../hooks/useAuth';
import { Icons } from '../../components/ui/Icons';
import Button from '../../components/ui/Button';

export default function Login() {
  const [formData, setFormData] = useState({
    email: '',
    password: ''
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      await login(formData.email, formData.password);
      router.push('/dashboard');
    } catch (error: any) {
      setError(error.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  const quickLogin = (username: string, password: string) => {
    setFormData({ email: username, password });
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-white flex items-center justify-center px-4 sm:px-6 lg:px-8">
      <div className="w-full max-w-md space-y-8">
        <div className="text-center">
          <div className="mx-auto w-16 h-16 bg-black rounded-2xl flex items-center justify-center mb-6 shadow-lg">
            <Icons.Container size={32} className="text-white" strokeWidth={1.5} />
          </div>
          <h1 className="text-3xl font-bold text-black tracking-tight">
            Container Manager
          </h1>
          <p className="mt-3 text-gray-600 font-medium">
            Multi-tenant Docker Platform
          </p>
        </div>

        <div className="mt-8">
          <div className="bg-white border border-gray-200 rounded-2xl p-8 shadow-sm">
            {error && (
              <div className="mb-6 bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg text-sm flex items-center gap-2">
                <Icons.AlertCircle size={16} />
                {error}
              </div>
            )}

            <form className="space-y-6" onSubmit={handleSubmit}>
              <div className="space-y-4">
                <div>
                  <label htmlFor="email" className="block text-sm font-semibold text-black mb-2">
                    Email
                  </label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <Icons.User size={18} className="text-gray-400" />
                    </div>
                    <input
                      id="email"
                      name="email"
                      type="email"
                      required
                      placeholder="admin@portail-cloud.com"
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-black focus:border-transparent transition-all duration-200 placeholder-gray-400"
                    />
                  </div>
                </div>

                <div>
                  <label htmlFor="password" className="block text-sm font-semibold text-black mb-2">
                    Password
                  </label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <Icons.Lock size={18} className="text-gray-400" />
                    </div>
                    <input
                      id="password"
                      name="password"
                      type="password"
                      required
                      value={formData.password}
                      onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                      className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-black focus:border-transparent transition-all duration-200"
                    />
                  </div>
                </div>
              </div>

              <Button
                type="submit"
                variant="primary"
                size="lg"
                isLoading={loading}
                className="w-full"
              >
                {loading ? 'Signing in...' : 'Sign In'}
              </Button>
            </form>

            <div className="mt-8">
              <div className="relative">
                <div className="absolute inset-0 flex items-center">
                  <div className="w-full border-t border-gray-200" />
                </div>
                <div className="relative flex justify-center text-xs uppercase">
                  <span className="bg-white px-4 text-gray-500 font-medium">Quick Access</span>
                </div>
              </div>
              <div className="mt-6 grid grid-cols-2 gap-2">
                {[
                  { username: 'admin@portail-cloud.com', password: 'admin123', label: 'Admin', icon: Icons.Users },
                  { username: 'client1@portail-cloud.com', password: 'client123', label: 'Client 1', icon: Icons.User },
                  { username: 'client2@portail-cloud.com', password: 'client123', label: 'Client 2', icon: Icons.User },
                  { username: 'client3@portail-cloud.com', password: 'client123', label: 'Client 3', icon: Icons.User }
                ].map((user) => (
                  <Button
                    key={user.username}
                    onClick={() => quickLogin(user.username, user.password)}
                    variant="outline"
                    size="sm"
                    className="flex-col h-auto py-3"
                  >
                    <user.icon size={16} className="mb-1" />
                    <span className="text-xs font-medium">{user.label}</span>
                  </Button>
                ))}
              </div>
            </div>
          </div>
        </div>

        <div className="mt-8 text-center">
          <p className="text-xs text-gray-500 font-medium">Powered by Docker & Next.js</p>
        </div>
      </div>
    </div>
  );
}