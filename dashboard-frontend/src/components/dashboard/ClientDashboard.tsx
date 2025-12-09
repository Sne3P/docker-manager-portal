import { useState, useEffect } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { api } from '../../lib/api';
import { Icons } from '../ui/Icons';
import Button from '../ui/Button';

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
  description?: string;
  networks?: string[];
  metrics?: {
    cpu: { usage: number; limit: number };
    memory: { usage: number; limit: number; percent: number; usageFormatted: string; limitFormatted: string };
    network: { rxBytes: number; txBytes: number; rxFormatted: string; txFormatted: string };
    uptime: number;
    lastUpdated: string;
  };
}

export default function ClientDashboard() {
  const { user } = useAuth();
  const [containers, setContainers] = useState<Container[]>([]);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    loadContainers();
  }, []);

  const loadContainers = async () => {
    try {
      setLoading(true);
      const response = await api.get('/api/containers/my');
      setContainers(response.data);
    } catch (error) {
      console.error('Erreur lors du chargement des conteneurs:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateService = async (serviceType: string) => {
    try {
      setCreating(true);
      await api.post('/api/containers/predefined', {
        serviceType
      });
      loadContainers(); // Recharger les conteneurs
    } catch (error) {
      console.error('Erreur lors de la création du service:', error);
    } finally {
      setCreating(false);
    }
  };

  const handleDeleteContainer = async (containerId: string) => {
    try {
      await api.delete(`/api/containers/${containerId}`);
      loadContainers(); // Recharger les conteneurs
    } catch (error) {
      console.error('Erreur lors de la suppression du conteneur:', error);
    }
  };

  const handleStartContainer = async (containerId: string) => {
    try {
      await api.post(`/api/containers/${containerId}/start`);
      loadContainers(); // Recharger les conteneurs
    } catch (error) {
      console.error('Erreur lors du démarrage du conteneur:', error);
    }
  };

  const handleStopContainer = async (containerId: string) => {
    try {
      await api.post(`/api/containers/${containerId}/stop`);
      loadContainers(); // Recharger les conteneurs
    } catch (error) {
      console.error('Erreur lors de l\'arrêt du conteneur:', error);
    }
  };

  if (loading) {
    return (
      <div className="min-h-[60vh] flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 bg-gray-100 rounded-xl flex items-center justify-center mb-4">
            <Icons.Loader size={24} className="text-gray-600" />
          </div>
          <p className="text-sm font-medium text-gray-600">Loading your containers...</p>
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
            <Icons.Container size={20} className="text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-black">My Containers</h1>
            <p className="text-gray-600 text-sm">Manage your deployed services and containers</p>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="bg-white border border-gray-200 rounded-2xl p-6">
        <div className="flex items-center gap-2 mb-6">
          <Icons.Server size={20} className="text-gray-600" />
          <h2 className="text-lg font-semibold text-black">Create New Service</h2>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            { type: 'nginx', label: 'Nginx', desc: 'Web Server', icon: Icons.Server, color: 'bg-green-50 border-green-200 hover:bg-green-100' },
            { type: 'nodejs', label: 'Node.js', desc: 'Application', icon: Icons.Container, color: 'bg-blue-50 border-blue-200 hover:bg-blue-100' },
            { type: 'python', label: 'Python', desc: 'Application', icon: Icons.Container, color: 'bg-purple-50 border-purple-200 hover:bg-purple-100' },
            { type: 'database', label: 'Database', desc: 'PostgreSQL/MySQL', icon: Icons.Server, color: 'bg-orange-50 border-orange-200 hover:bg-orange-100' }
          ].map((service) => (
            <Button
              key={service.type}
              onClick={() => handleCreateService(service.type)}
              variant="outline"
              size="md"
              disabled={creating}
              className={`h-auto p-4 flex-col gap-2 ${service.color} transition-all duration-200`}
            >
              <service.icon size={24} className="text-gray-600" />
              <div className="text-center">
                <div className="font-semibold text-black">{service.label}</div>
                <div className="text-xs text-gray-500">{service.desc}</div>
              </div>
            </Button>
          ))}
        </div>
        {creating && (
          <div className="mt-4 flex items-center gap-2 text-sm text-gray-600">
            <Icons.Loader size={16} />
            <span>Creating service...</span>
          </div>
        )}
      </div>

      {/* Containers Overview */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {[
          {
            title: 'Total Containers',
            value: containers.length,
            description: 'Deployed services',
            icon: Icons.Container,
            color: 'bg-blue-50 text-blue-600'
          },
          {
            title: 'Running',
            value: containers.filter(c => c.status === 'running').length,
            description: 'Active containers',
            icon: Icons.CheckCircle,
            color: 'bg-green-50 text-green-600'
          },
          {
            title: 'Stopped',
            value: containers.filter(c => c.status === 'stopped').length,
            description: 'Inactive containers',
            icon: Icons.XCircle,
            color: 'bg-red-50 text-red-600'
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

      {/* Containers List */}
      <div className="bg-white border border-gray-200 rounded-2xl overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200 bg-gray-50">
          <h2 className="text-lg font-semibold text-black flex items-center gap-2">
            <Icons.Container size={20} />
            Your Containers ({containers.length})
          </h2>
        </div>
        <div className="p-6">
          {containers.length === 0 ? (
            <div className="text-center py-12">
              <div className="w-16 h-16 bg-gray-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
                <Icons.Container size={32} className="text-gray-400" />
              </div>
              <h3 className="text-lg font-semibold text-black mb-2">
                No containers deployed
              </h3>
              <p className="text-gray-500 mb-4">
                Start by creating your first service above
              </p>
            </div>
          ) : (
            <div className="grid gap-4">
              {containers.map((container, index) => {
                const statusConfig = {
                  running: { color: 'bg-green-100 text-green-700', icon: Icons.CheckCircle },
                  stopped: { color: 'bg-red-100 text-red-700', icon: Icons.XCircle },
                  pending: { color: 'bg-yellow-100 text-yellow-700', icon: Icons.AlertCircle }
                };
                
                const status = statusConfig[container.status as keyof typeof statusConfig] || statusConfig.pending;
                
                return (
                  <div 
                    key={container.id} 
                    className="border border-gray-200 rounded-xl p-5 hover:border-gray-300 hover:shadow-sm transition-all duration-200"
                    style={{ animationDelay: `${index * 50}ms` }}
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex items-start gap-3 flex-1">
                        <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center flex-shrink-0">
                          <Icons.Container size={18} className="text-gray-600" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-3 mb-2">
                            <h4 className="font-semibold text-black truncate">{container.name}</h4>
                            <span className={`inline-flex items-center gap-1 px-2.5 py-1 text-xs font-semibold rounded-full ${status.color}`}>
                              <status.icon size={12} />
                              {container.status}
                            </span>
                          </div>
                          <div className="space-y-1">
                            <div className="flex items-center gap-2 text-sm text-gray-600">
                              <Icons.Server size={14} />
                              <span>Type: <span className="font-medium">{container.serviceType}</span></span>
                            </div>
                            {container.url && (
                              <div className="flex items-center gap-2 text-sm">
                                <Icons.ExternalLink size={14} className="text-gray-400" />
                                <a
                                  href={container.url}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="text-black hover:text-gray-700 font-medium underline underline-offset-2"
                                >
                                  {container.url}
                                </a>
                              </div>
                            )}
                            <div className="text-xs text-gray-500">
                              Created {new Date(container.createdAt).toLocaleDateString()}
                            </div>
                            {container.metrics && (
                              <div className="mt-3 p-3 bg-gray-50 rounded-lg">
                                <div className="text-xs font-medium text-gray-600 mb-2">Metrics</div>
                                <div className="grid grid-cols-3 gap-3">
                                  <div className="text-center">
                                    <div className="flex items-center justify-center gap-1 mb-1">
                                      <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                                      <span className="text-xs font-medium text-gray-600">CPU</span>
                                    </div>
                                    <div className="text-sm font-semibold text-blue-600">{container.metrics.cpu.usage}%</div>
                                  </div>
                                  <div className="text-center">
                                    <div className="flex items-center justify-center gap-1 mb-1">
                                      <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                                      <span className="text-xs font-medium text-gray-600">Memory</span>
                                    </div>
                                    <div className="text-sm font-semibold text-green-600">{container.metrics.memory.usageFormatted}</div>
                                  </div>
                                  <div className="text-center">
                                    <div className="flex items-center justify-center gap-1 mb-1">
                                      <div className="w-2 h-2 bg-purple-500 rounded-full"></div>
                                      <span className="text-xs font-medium text-gray-600">Network</span>
                                    </div>
                                    <div className="text-xs font-semibold text-purple-600">
                                      ↓{container.metrics.network.rxFormatted}
                                    </div>
                                    <div className="text-xs font-semibold text-purple-600">
                                      ↑{container.metrics.network.txFormatted}
                                    </div>
                                  </div>
                                </div>
                              </div>
                            )}
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center gap-2 ml-4">
                        {container.status === 'running' ? (
                          <Button
                            onClick={() => handleStopContainer(container.id)}
                            variant="outline"
                            size="xs"
                            leftIcon={<Icons.Stop size={14} />}
                            className="border-red-200 text-red-600 hover:bg-red-50"
                          >
                            Stop
                          </Button>
                        ) : (
                          <Button
                            onClick={() => handleStartContainer(container.id)}
                            variant="outline"
                            size="xs"
                            leftIcon={<Icons.Play size={14} />}
                            className="border-green-200 text-green-600 hover:bg-green-50"
                          >
                            Start
                          </Button>
                        )}
                        <Button
                          onClick={() => handleDeleteContainer(container.id)}
                          variant="danger"
                          size="xs"
                          leftIcon={<Icons.Trash size={14} />}
                        >
                          Delete
                        </Button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}