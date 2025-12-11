import { useState, useEffect } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { api } from '../../lib/api';
import { Icons } from '../ui/Icons';
import Button from '../ui/Button';

interface Client {
  id: number;
  name: string;
  email: string;
  createdAt: string;
  isActive: boolean;
  containerQuota: number;
  totalContainers: number;
  runningContainers: number;
  stoppedContainers: number;
  role: string;
}

interface Container {
  id: string;
  name: string;
  clientId: string;
  serviceType: string;
  status: string;
  image: string;
  url?: string;
  ports: any[];
  createdAt: string;
  description: string;
  networks: string[];
  metrics?: {
    cpu: { usage: number; limit: number };
    memory: { usage: number; limit: number; percent: number; usageFormatted: string; limitFormatted: string };
    network: { rxBytes: number; txBytes: number; rxFormatted: string; txFormatted: string };
    uptime: number;
    lastUpdated: string;
  };
}

export default function AdminDashboard() {
  const { user } = useAuth();
  const [clients, setClients] = useState<Client[]>([]);
  const [containers, setContainers] = useState<Container[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'overview' | 'clients' | 'containers'>('overview');

  useEffect(() => {
    if (user?.role === 'admin') {
      loadAdminData();
    }
  }, [user]);

  const loadAdminData = async () => {
    try {
      setLoading(true);
      
      const [clientsRes, containersRes] = await Promise.all([
        api.get('/admin/clients'),
        api.get('/admin/containers')
      ]);
      
      setClients(clientsRes.data || []);
      setContainers(containersRes.data || []);
    } catch (error) {
      console.error('Failed to load admin data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleContainerAction = async (containerId: string, action: 'start' | 'stop' | 'restart' | 'remove') => {
    if (action === 'remove' && !confirm('Are you sure you want to delete this container?')) {
      return;
    }

    try {
      await api.post(`/api/admin/containers/${containerId}/${action}`);
      loadAdminData(); // Refresh data
    } catch (error) {
      console.error(`Failed to ${action} container:`, error);
      alert(`Failed to ${action} container`);
    }
  };

  if (user?.role !== 'admin') {
    return (
      <div className="min-h-screen bg-white flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-xl font-bold text-red-600">Access Denied</h2>
          <p className="text-gray-600 mt-2">Admin privileges required</p>
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="min-h-[60vh] flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 bg-gray-100 rounded-xl flex items-center justify-center mb-4">
            <Icons.Loader size={24} className="text-gray-600" />
          </div>
          <p className="text-sm font-medium text-gray-600">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="border-b border-gray-200 pb-6">
        <div className="flex items-center gap-3 mb-2">
          <div className="w-10 h-10 bg-black rounded-xl flex items-center justify-center">
            <Icons.Dashboard size={20} className="text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-black">Admin Dashboard</h1>
            <p className="text-gray-600 text-sm">Platform management and client overview</p>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex flex-col sm:flex-row gap-1 p-1 bg-gray-100 rounded-xl">
        {[
          { key: 'overview', label: 'Overview', icon: Icons.Dashboard },
          { key: 'clients', label: 'Clients', icon: Icons.Users },
          { key: 'containers', label: 'Containers', icon: Icons.Container }
        ].map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key as any)}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-lg font-medium text-sm transition-all duration-200 ${
              activeTab === tab.key
                ? 'bg-white text-black shadow-sm'
                : 'text-gray-600 hover:text-black hover:bg-white/50'
            }`}
          >
            <tab.icon size={16} />
            {tab.label}
          </button>
        ))}
      </div>

      {/* Overview Tab */}
      {activeTab === 'overview' && (
        <div className="animate-in fade-in duration-300">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {[
              {
                title: 'Total Clients',
                value: clients.length,
                description: 'Active platform clients',
                icon: Icons.Users,
                color: 'bg-blue-50 text-blue-600'
              },
              {
                title: 'Total Containers',
                value: containers.length,
                description: 'Managed containers',
                icon: Icons.Container,
                color: 'bg-green-50 text-green-600'
              },
              {
                title: 'Active Containers',
                value: containers.filter(c => c.status === 'running').length,
                description: 'Currently running',
                icon: Icons.CheckCircle,
                color: 'bg-emerald-50 text-emerald-600'
              }
            ].map((stat, index) => (
              <div
                key={stat.title}
                className="group bg-white border border-gray-200 rounded-2xl p-6 hover:border-gray-300 hover:shadow-sm transition-all duration-200"
                style={{ animationDelay: `${index * 100}ms` }}
              >
                <div className="flex items-center justify-between mb-4">
                  <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${stat.color}`}>
                    <stat.icon size={24} />
                  </div>
                </div>
                <h3 className="text-sm font-semibold text-gray-600 mb-2">{stat.title}</h3>
                <p className="text-3xl font-bold text-black mb-1">{stat.value}</p>
                <p className="text-xs text-gray-500">{stat.description}</p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Clients Tab */}
      {activeTab === 'clients' && (
        <div className="animate-in fade-in duration-300">
          <div className="bg-white border border-gray-200 rounded-2xl overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-200 bg-gray-50">
              <h2 className="text-lg font-semibold text-black flex items-center gap-2">
                <Icons.Users size={20} />
                Clients ({clients.length})
              </h2>
            </div>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                      Client
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                      Email
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                      Role
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                      Containers
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                      Status
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {clients.map((client, index) => (
                    <tr 
                      key={client.id} 
                      className="hover:bg-gray-50 transition-colors duration-150"
                      style={{ animationDelay: `${index * 50}ms` }}
                    >
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 bg-gray-100 rounded-lg flex items-center justify-center">
                            <Icons.User size={16} className="text-gray-600" />
                          </div>
                          <div className="text-sm font-semibold text-black">{client.name}</div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-600">{client.email}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 text-xs font-semibold rounded-full bg-gray-100 text-gray-700">
                          <Icons.User size={12} />
                          Client
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="space-y-1">
                          <div className="text-blue-600 font-semibold">{client.runningContainers} actifs</div>
                          <div className="text-gray-500 text-xs">{client.totalContainers} total</div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-700">
                          <Icons.CheckCircle size={12} />
                          Active
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Containers Tab */}
      {activeTab === 'containers' && (
        <div className="animate-in fade-in duration-300">
          <div className="bg-white border border-gray-200 rounded-2xl overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-200 bg-gray-50">
              <h2 className="text-lg font-semibold text-black flex items-center gap-2">
                <Icons.Container size={20} />
                Containers ({containers.length})
              </h2>
            </div>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                      Container
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                      Image
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                      Owner
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                      Status
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                      Métriques
                    </th>
                    <th className="px-6 py-3 text-right text-xs font-semibold text-gray-600 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {containers.map((container, index) => {
                    const statusConfig = {
                      running: { color: 'bg-green-100 text-green-700', icon: Icons.CheckCircle },
                      stopped: { color: 'bg-red-100 text-red-700', icon: Icons.XCircle },
                      exited: { color: 'bg-red-100 text-red-700', icon: Icons.XCircle },
                      pending: { color: 'bg-yellow-100 text-yellow-700', icon: Icons.AlertCircle }
                    };
                    
                    const status = statusConfig[container.status as keyof typeof statusConfig] || statusConfig.pending;
                    
                    return (
                      <tr 
                        key={container.id} 
                        className="hover:bg-gray-50 transition-colors duration-150"
                        style={{ animationDelay: `${index * 50}ms` }}
                      >
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center gap-3">
                            <div className="w-8 h-8 bg-gray-100 rounded-lg flex items-center justify-center">
                              <Icons.Container size={16} className="text-gray-600" />
                            </div>
                            <div>
                              <div className="text-sm font-semibold text-black">{container.name}</div>
                              <div className="text-xs text-gray-500 font-mono">{container.id.substring(0, 12)}...</div>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm text-gray-600 font-mono">{container.image}</div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center gap-2 text-sm text-gray-600">
                            <Icons.User size={14} />
                            {clients.find(c => c.id.toString() === container.clientId)?.name || container.clientId}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span className={`inline-flex items-center gap-1 px-2.5 py-1 text-xs font-semibold rounded-full ${status.color}`}>
                            <status.icon size={12} />
                            {container.status}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          {container.metrics ? (
                            <div className="space-y-1">
                              <div className="flex items-center gap-2">
                                <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                                <span className="text-xs text-gray-600">CPU {container.metrics.cpu.usage}%</span>
                              </div>
                              <div className="flex items-center gap-2">
                                <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                                <span className="text-xs text-gray-600">{container.metrics.memory.usageFormatted}</span>
                              </div>
                              <div className="flex items-center gap-2">
                                <div className="w-2 h-2 bg-purple-500 rounded-full"></div>
                                <span className="text-xs text-gray-600">↓{container.metrics.network.rxFormatted}</span>
                              </div>
                            </div>
                          ) : (
                            <span className="text-xs text-gray-400">-</span>
                          )}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-right">
                          <div className="flex items-center gap-2 justify-end">
                            {container.status === 'running' ? (
                              <Button
                                onClick={() => handleContainerAction(container.id, 'stop')}
                                variant="outline"
                                size="xs"
                                leftIcon={<Icons.Pause size={14} />}
                              >
                                Stop
                              </Button>
                            ) : (
                              <Button
                                onClick={() => handleContainerAction(container.id, 'start')}
                                variant="secondary"
                                size="xs"
                                leftIcon={<Icons.Play size={14} />}
                              >
                                Start
                              </Button>
                            )}
                            <Button
                              onClick={() => handleContainerAction(container.id, 'remove')}
                              variant="danger"
                              size="xs"
                              leftIcon={<Icons.Trash size={14} />}
                            >
                              Delete
                            </Button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}