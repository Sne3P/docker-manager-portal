import { useState, useEffect } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { api } from '../../lib/api';

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
      <div className="flex items-center justify-center min-h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        <span className="ml-2">Chargement de vos conteneurs...</span>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Mes Services Docker</h1>
        <p className="text-gray-600">Gérez vos conteneurs et services déployés</p>
      </div>

      {/* Quick Actions */}
      <div className="bg-white p-6 rounded-lg shadow-sm border mb-8">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">🚀 Créer un nouveau service</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { type: 'nginx', label: '🌐 Nginx Web Server', desc: 'Serveur web haute performance' },
            { type: 'nodejs', label: '🟢 Node.js App', desc: 'Application Node.js' },
            { type: 'python', label: '🐍 Python App', desc: 'Application Python' },
            { type: 'database', label: '🗄️ Base de données', desc: 'PostgreSQL ou MySQL' }
          ].map((service) => (
            <button
              key={service.type}
              onClick={() => handleCreateService(service.type)}
              disabled={creating}
              className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 text-left disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <div className="font-medium text-gray-900">{service.label}</div>
              <div className="text-sm text-gray-500 mt-1">{service.desc}</div>
            </button>
          ))}
        </div>
        {creating && (
          <div className="mt-4 text-blue-600 text-sm">
            ⏳ Création du service en cours...
          </div>
        )}
      </div>

      {/* Containers Overview */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Mes Conteneurs</h3>
          <p className="text-3xl font-bold text-blue-600">{containers.length}</p>
          <p className="text-sm text-gray-500">Services déployés</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Actifs</h3>
          <p className="text-3xl font-bold text-green-600">
            {containers.filter(c => c.status === 'running').length}
          </p>
          <p className="text-sm text-gray-500">En cours d'exécution</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Arrêtés</h3>
          <p className="text-3xl font-bold text-red-600">
            {containers.filter(c => c.status === 'stopped').length}
          </p>
          <p className="text-sm text-gray-500">Services arrêtés</p>
        </div>
      </div>

      {/* Containers List */}
      <div className="bg-white shadow-sm rounded-lg">
        <div className="px-4 py-5 sm:p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Vos Conteneurs</h3>
          {containers.length === 0 ? (
            <div className="text-center py-8">
              <div className="text-gray-400 text-4xl mb-4">🐳</div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                Aucun conteneur déployé
              </h3>
              <p className="text-gray-500">
                Commencez par créer votre premier service ci-dessus
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {containers.map((container) => (
                <div key={container.id} className="border border-gray-200 rounded-lg p-4">
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <div className="flex items-center space-x-3">
                        <h4 className="font-medium text-gray-900">{container.containerName}</h4>
                        <span className={`px-2 py-1 text-xs font-semibold rounded-full ${
                          container.status === 'running'
                            ? 'bg-green-100 text-green-800'
                            : container.status === 'stopped'
                            ? 'bg-red-100 text-red-800'
                            : 'bg-gray-100 text-gray-800'
                        }`}>
                          {container.status}
                        </span>
                      </div>
                      <div className="mt-1 space-y-1">
                        <p className="text-sm text-gray-600">
                          Type: <span className="font-medium">{container.serviceType}</span>
                        </p>
                        {container.url && (
                          <p className="text-sm text-gray-600">
                            URL: <a
                              href={container.url}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="text-blue-600 hover:text-blue-900 font-medium"
                            >
                              {container.url}
                            </a>
                          </p>
                        )}
                        <p className="text-xs text-gray-400">
                          Créé le {new Date(container.createdAt).toLocaleDateString()}
                        </p>
                      </div>
                    </div>
                    <div className="flex space-x-2">
                      {container.status === 'running' ? (
                        <button
                          onClick={() => handleStopContainer(container.id)}
                          className="px-3 py-1 bg-red-100 text-red-700 rounded-md text-sm font-medium hover:bg-red-200"
                        >
                          ⏹️ Arrêter
                        </button>
                      ) : (
                        <button
                          onClick={() => handleStartContainer(container.id)}
                          className="px-3 py-1 bg-green-100 text-green-700 rounded-md text-sm font-medium hover:bg-green-200"
                        >
                          ▶️ Démarrer
                        </button>
                      )}
                      <button
                        onClick={() => handleDeleteContainer(container.id)}
                        className="px-3 py-1 bg-gray-100 text-gray-700 rounded-md text-sm font-medium hover:bg-gray-200"
                      >
                        🗑️ Supprimer
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}