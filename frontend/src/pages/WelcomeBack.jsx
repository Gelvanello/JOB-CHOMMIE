import React from 'react';
import { Link } from 'react-router-dom';

const WelcomeBack = () => {
  return (
    <div className="py-8 bg-gray-50 min-h-screen flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">Welcome Back!</h1>
        <p className="text-gray-700 mb-6">We're glad to see you again. Continue exploring opportunities.</p>
        <Link to="/dashboard" className="bg-blue-600 text-white px-6 py-3 rounded-md hover:bg-blue-700 transition-colors">
          Go to Dashboard
        </Link>
      </div>
    </div>
  );
};

export default WelcomeBack;
