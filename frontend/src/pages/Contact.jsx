import React from 'react';

const Contact = () => {
  return (
    <div className="py-8 bg-gray-50 min-h-screen">
      <div className="max-w-3xl mx-auto p-4">
        <h1 className="text-3xl font-bold text-gray-900 mb-4">Contact Us</h1>
        <p className="text-gray-700 mb-4">
          Got questions or feedback? Send us a message at <a href="mailto:support@aijobchommie.com" className="text-blue-600 hover:underline">support@aijobchommie.com</a>.
        </p>
      </div>
    </div>
  );
};

export default Contact;
