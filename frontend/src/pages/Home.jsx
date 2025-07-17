import { Link } from 'react-router-dom';

function Home() {
  return (
    <div className="py-8">
      <div className="text-center max-w-4xl mx-auto">
        <h1 className="text-5xl font-bold text-gray-900 mb-6 leading-tight">
          Welcome to AI Job Chommie
        </h1>
        
        <p className="text-xl text-gray-600 mb-8 leading-relaxed">
          Your AI-powered job search companion. Let's find your perfect career match together.
        </p>
        
        <div className="flex justify-center gap-4">
          <Link
            to="/jobs"
            className="bg-blue-600 text-white px-8 py-3 rounded-lg font-semibold hover:bg-blue-700 transition-colors shadow-md hover:shadow-lg"
          >
            Start Searching
          </Link>
          <Link
            to="/profile"
            className="bg-gray-100 text-gray-700 px-8 py-3 rounded-lg font-semibold hover:bg-gray-200 transition-colors border border-gray-300"
          >
            Complete Profile
          </Link>
        </div>
      </div>
    </div>
  );
}

export default Home;
