import React from 'react';

const Loading = () => {
  return (
    <div className="py-8 bg-gray-50 min-h-screen flex items-center justify-center">
      <div className="animate-spin rounded-full h-16 w-16 border-t-4 border-blue-600"></div>
      <p className="ml-4 text-gray-700 text-lg">Loading...</p>
    </div>
  );
};

export default Loading;
