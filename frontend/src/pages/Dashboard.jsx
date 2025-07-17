import React from 'react';
import {
  BriefcaseIcon,
  ListIcon,
  CalendarIcon,
  UserIcon,
} from 'lucide-react';
import Banner from '../components/Banner';
import ThreeHero from '../components/ThreeHero';

const Dashboard = () => {
  const stats = [
    {
      id: 1,
      title: 'Total Jobs',
      value: 128,
      icon: <BriefcaseIcon className="w-6 h-6 text-blue-500" />,
    },
    {
      id: 2,
      title: 'Applications',
      value: 54,
      icon: <ListIcon className="w-6 h-6 text-green-500" />,
    },
    {
      id: 3,
      title: 'Interviews',
      value: 8,
      icon: <CalendarIcon className="w-6 h-6 text-yellow-500" />,
    },
    {
      id: 4,
      title: 'Profile Complete',
      value: '75%',
      icon: <UserIcon className="w-6 h-6 text-purple-500" />,
    },
  ];

  const recentActivities = [
    { id: 1, activity: 'Profile updated', time: '1 day ago' },
    { id: 2, activity: 'New job matches available', time: '2 days ago' },
    { id: 3, activity: 'Interview scheduled: Frontend Dev', time: '3 days ago' },
    { id: 4, activity: 'Application submitted: Data Analyst', time: '4 days ago' },
  ];

  return (
    <div className="py-8 bg-gray-50 min-h-screen">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-6">Dashboard</h1>
<Banner />
<ThreeHero />

        {/* Stats Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {stats.map(({ id, title, value, icon }) => (
            <div
              key={id}
              className="bg-white shadow rounded-lg p-5 flex items-center"
            >
              <div className="p-3 bg-blue-100 rounded-full mr-4">
                {icon}
              </div>
              <div>
                <p className="text-2xl font-semibold text-gray-900">{value}</p>
                <p className="text-sm text-gray-500">{title}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Recent Activity */}
        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">
            Recent Activity
          </h2>
          <ul className="divide-y divide-gray-200">
            {recentActivities.map(({ id, activity, time }) => (
              <li
                key={id}
                className="py-3 flex justify-between items-center"
              >
                <span className="text-gray-700">{activity}</span>
                <span className="text-sm text-gray-400">{time}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;