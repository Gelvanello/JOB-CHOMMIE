import React, { useState } from 'react';

const Settings = () => {
  const [settings, setSettings] = useState({
    notifications: true,
    darkMode: false,
  });

  const handleToggle = (key) => {
    setSettings(prev => ({ ...prev, [key]: !prev[key] }));
  };

  return (
    <div className="py-8 bg-gray-50 min-h-screen">
      <div className="max-w-3xl mx-auto p-4">
        <h1 className="text-3xl font-bold text-gray-900 mb-4">Settings</h1>
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <span>Enable Notifications</span>
            <button onClick={() => handleToggle('notifications')} className={`px-4 py-2 rounded ${settings.notifications ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-800'}`}>
              {settings.notifications ? 'On' : 'Off'}
            </button>
          </div>
          <div className="flex items-center justify-between">
            <span>Dark Mode</span>
            <button onClick={() => handleToggle('darkMode')} className={`px-4 py-2 rounded ${settings.darkMode ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-800'}`}>
              {settings.darkMode ? 'On' : 'Off'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Settings;
