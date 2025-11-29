import { useState, useEffect } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { api } from '../../lib/api';

interface Client {
  id: string;
  name: string;
  email: string;
  createdAt: string;
}

interface Container {
  id: string;
  clientId: string;
  serviceType: string;
  containerName: string;
  status: string;
  url?: string;
  ports: any[];
  createdAt: string;
}

export default function AdminDashboard() {
  const { user } = useAuth();
  const [clients, setClients] = useState<Client[]>([]);
  const [containers, setContainers] = useState<Container[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'overview' | 'clients' | 'containers'>('overview');

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      const [clientsData, containersData] = await Promise.all([
        api.get('/api/admin/clients'),
        api.get('/api/containers')
      ]);
      setClients(clientsData.data);
      setContainers(containersData.data);
    } catch (error) {
      console.error('Erreur lors du chargement des données:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateService = async (clientId: string, serviceType: string) => {
    try {
      await api.post('/api/containers/predefined', {
        clientId,
        serviceType
      });
      loadData(); // Recharger les données
    } catch (error) {
      console.error('Erreur lors de la création du service:', error);
    }
  };

  const handleDeleteContainer = async (containerId: string) => {
    try {
      await api.delete(`/api/containers/${containerId}`);
      loadData(); // Recharger les données
    } catch (error) {
      console.error('Erreur lors de la suppression du conteneur:', error);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        <span className="ml-2">Chargement...</span>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Tableau de bord Administrateur</h1>
        <p className="text-gray-600">Gestion complète de la plateforme et des clients</p>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200 mb-6">
        <nav className="-mb-px flex space-x-8">
          {[
            { key: 'overview', label: '📊 Vue d\'ensemble' },
            { key: 'clients', label: '👥 Clients' },
            { key: 'containers', label: '🐳 Conteneurs' }
          ].map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key as any)}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === tab.key
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </nav>
      </div>

      {/* Overview Tab */}
      {activeTab === 'overview' && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-white p-6 rounded-lg shadow-sm border">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Total Clients</h3>
            <p className="text-3xl font-bold text-blue-600">{clients.length}</p>
            <p className="text-sm text-gray-500">Clients actifs sur la plateforme</p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow-sm border">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Total Conteneurs</h3>
            <p className="text-3xl font-bold text-green-600">{containers.length}</p>
            <p className="text-sm text-gray-500">Conteneurs déployés</p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow-sm border">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Conteneurs Actifs</h3>
            <p className="text-3xl font-bold text-orange-600">
              {containers.filter(c => c.status === 'running').length}
            </p>
            <p className="text-sm text-gray-500">Conteneurs en cours d'exécution</p>
          </div>
        </div>
      )}

      {/* Clients Tab */}
      {activeTab === 'clients' && (
        <div className="bg-white shadow-sm rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Gestion des Clients</h3>
            <div className="space-y-4">
              {clients.map((client) => (
                <div key={client.id} className="border border-gray-200 rounded-lg p-4">
                  <div className="flex justify-between items-start">
                    <div>
                      <h4 className="font-medium text-gray-900">{client.name}</h4>
                      <p className="text-sm text-gray-500">{client.email}</p>
                      <p className="text-xs text-gray-400">
                        Créé le {new Date(client.createdAt).toLocaleDateString()}
                      </p>
                    </div>
                    <div className="flex space-x-2">
                      <select
                        className="text-sm border border-gray-300 rounded-md px-2 py-1"
                        onChange={(e) => {
                          if (e.target.value) {
                            handleCreateService(client.id, e.target.value);
                            e.target.value = '';
                          }
                        }}
                      >
                        <option value="">Créer un service...</option>
                        <option value="nginx">🌐 Nginx Web Server</option>
                        <option value="nodejs">🟢 Node.js App</option>
                        <option value="python">🐍 Python App</option>
                        <option value="database">🗄️ Base de données</option>
                      </select>
                    </div>
                  </div>
                  <div className="mt-3">
                    <p className="text-sm text-gray-600">
                      Conteneurs: {containers.filter(c => c.clientId === client.id).length}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Containers Tab */}
      {activeTab === 'containers' && (
        <div className="bg-white shadow-sm rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Tous les Conteneurs</h3>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Conteneur
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Client
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Service
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Statut
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      URL
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {containers.map((container) => {
                    const client = clients.find(c => c.id === container.clientId);
                    return (
                      <tr key={container.id}>
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                          {container.containerName}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {client?.name || container.clientId}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {container.serviceType}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span className={`px-2 py-1 text-xs font-semibold rounded-full ${
                            container.status === 'running'
                              ? 'bg-green-100 text-green-800'
                              : container.status === 'stopped'
                              ? 'bg-red-100 text-red-800'
                              : 'bg-gray-100 text-gray-800'
                          }`}>
                            {container.status}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {container.url ? (
                            <a
                              href={container.url}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="text-blue-600 hover:text-blue-900"
                            >
                              {container.url}
                            </a>
                          ) : (
                            '-'
                          )}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          <button
                            onClick={() => handleDeleteContainer(container.id)}
                            className="text-red-600 hover:text-red-900 text-sm font-medium"
                          >
                            🗑️ Supprimer
                          </button>
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