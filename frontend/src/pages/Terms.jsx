import React from 'react';

const Terms = () => {
  return (
    <div className="py-8 bg-gray-50 min-h-screen">
      <div className="max-w-3xl mx-auto p-4">
        <h1 className="text-3xl font-bold text-gray-900 mb-4">Terms & Conditions</h1>
        <p className="text-gray-700 mb-4">
          Please read these terms and conditions carefully before using the AI Job Chommie application.
        </p>
        <ol className="list-decimal list-inside text-gray-700 space-y-2">
          <li>Acceptance of Terms: By using the application, you agree to abide by these terms.</li>
          <li>Use License: Permission is granted to temporarily download one copy of the materials.</li>
          <li>User Conduct: You must not misuse the application.</li>
          <li>Limitation of Liability: AI Job Chommie is not liable for any damages arising from use.</li>
          <li>Modifications: We may revise these terms at any time without notice.</li>
        </ol>
      </div>
    </div>
  );
};

export default Terms;
