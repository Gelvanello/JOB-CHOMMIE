import React from 'react';

const Privacy = () => {
  return (
    <div className="py-8 bg-gray-50 min-h-screen">
      <div className="max-w-3xl mx-auto p-4">
        <h1 className="text-3xl font-bold text-gray-900 mb-4">Privacy Policy</h1>
        <p className="text-gray-700 mb-4">
          Your privacy is important to us. This policy explains how we collect, use, and protect your personal information.
        </p>
        <ul className="list-disc list-inside text-gray-700 space-y-2">
          <li>Information Collection: We collect data to improve user experience.</li>
          <li>Use of Data: Data is used solely for application functionality.</li>
          <li>Data Protection: We implement security measures to protect your data.</li>
          <li>Third-Party Services: We do not share personal data with external parties.</li>
          <li>Changes to Policy: We may update this policy and will notify users.</li>
        </ul>
      </div>
    </div>
  );
};

export default Privacy;
