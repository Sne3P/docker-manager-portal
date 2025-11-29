import { useRouter } from 'next/router';

export default function TestPage() {
  const router = useRouter();

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          {/* Header */}
          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold text-gray-900 mb-4">
              🎨 Style Test Page
            </h1>
            <p className="text-lg text-gray-600">
              Testing Tailwind CSS styles
            </p>
          </div>

          {/* Cards Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
            <div className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
              <div className="flex items-center mb-4">
                <div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center">
                  <span className="text-white font-bold">1</span>
                </div>
                <h3 className="ml-3 text-lg font-semibold text-gray-900">Card 1</h3>
              </div>
              <p className="text-gray-600">
                This is a test card with Tailwind styling.
              </p>
            </div>

            <div className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
              <div className="flex items-center mb-4">
                <div className="w-10 h-10 bg-green-500 rounded-full flex items-center justify-center">
                  <span className="text-white font-bold">2</span>
                </div>
                <h3 className="ml-3 text-lg font-semibold text-gray-900">Card 2</h3>
              </div>
              <p className="text-gray-600">
                Another test card to verify styles are working.
              </p>
            </div>

            <div className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
              <div className="flex items-center mb-4">
                <div className="w-10 h-10 bg-purple-500 rounded-full flex items-center justify-center">
                  <span className="text-white font-bold">3</span>
                </div>
                <h3 className="ml-3 text-lg font-semibold text-gray-900">Card 3</h3>
              </div>
              <p className="text-gray-600">
                Third card to complete the test grid.
              </p>
            </div>
          </div>

          {/* Buttons */}
          <div className="flex flex-wrap gap-4 justify-center mb-8">
            <button className="bg-blue-500 hover:bg-blue-600 text-white font-medium px-6 py-3 rounded-lg transition-colors">
              Primary Button
            </button>
            <button className="bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium px-6 py-3 rounded-lg transition-colors">
              Secondary Button
            </button>
            <button className="bg-green-500 hover:bg-green-600 text-white font-medium px-6 py-3 rounded-lg transition-colors">
              Success Button
            </button>
            <button className="bg-red-500 hover:bg-red-600 text-white font-medium px-6 py-3 rounded-lg transition-colors">
              Danger Button
            </button>
          </div>

          {/* Alert Box */}
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-8">
            <div className="flex items-center">
              <div className="text-blue-400 mr-3">ℹ️</div>
              <div>
                <h4 className="text-blue-800 font-medium">Info</h4>
                <p className="text-blue-700 text-sm">
                  If you can see this styled properly, Tailwind CSS is working correctly!
                </p>
              </div>
            </div>
          </div>

          {/* Back to Dashboard */}
          <div className="text-center">
            <button
              onClick={() => router.push('/dashboard')}
              className="bg-indigo-500 hover:bg-indigo-600 text-white font-medium px-8 py-3 rounded-lg transition-colors inline-flex items-center"
            >
              <span className="mr-2">←</span>
              Back to Dashboard
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}