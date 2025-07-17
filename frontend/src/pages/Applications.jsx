import { useState } from 'react';
import { FileTextIcon, CalendarIcon, BuildingIcon, MapPinIcon, FilterIcon } from 'lucide-react';

const Applications = () => {
  const [filter, setFilter] = useState('all');
  
  const applications = [
    {
      id: 1,
      company: 'TechCorp SA',
      position: 'Senior Software Developer',
      location: 'Cape Town, Western Cape',
      appliedDate: '2024-07-10',
      status: 'interview',
      nextStep: 'Technical Interview on July 16',
      salary: 'R60,000 - R80,000'
    },
    {
      id: 2,
      company: 'Digital Solutions',
      position: 'Frontend Developer',
      location: 'Johannesburg, Gauteng',
      appliedDate: '2024-07-07',
      status: 'review',
      nextStep: 'Awaiting response',
      salary: 'R45,000 - R65,000'
    },
    {
      id: 3,
      company: 'Analytics Pro',
      position: 'Data Analyst',
      location: 'Durban, KwaZulu-Natal',
      appliedDate: '2024-07-12',
      status: 'applied',
      nextStep: 'Application submitted',
      salary: 'R35,000 - R50,000'
    },
    {
      id: 4,
      company: 'Creative Studio',
      position: 'UI/UX Designer',
      location: 'Cape Town, Western Cape',
      appliedDate: '2024-07-05',
      status: 'rejected',
      nextStep: 'Position filled',
      salary: 'R40,000 - R60,000'
    },
    {
      id: 5,
      company: 'StartupCo',
      position: 'Full Stack Developer',
      location: 'Remote',
      appliedDate: '2024-07-13',
      status: 'applied',
      nextStep: 'Application submitted',
      salary: 'R50,000 - R70,000'
    }
  ];

  const getStatusColor = (status) => {
    switch (status) {
      case 'interview':
        return 'bg-green-100 text-green-800';
      case 'review':
        return 'bg-yellow-100 text-yellow-800';
      case 'applied':
        return 'bg-blue-100 text-blue-800';
      case 'rejected':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusText = (status) => {
    switch (status) {
      case 'interview':
        return 'Interview Scheduled';
      case 'review':
        return 'Under Review';
      case 'applied':
        return 'Applied';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  };

  const filteredApplications = applications.filter(app => {
    if (filter === 'all') return true;
    return app.status === filter;
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <h1 className="text-3xl font-bold text-gray-900">My Applications</h1>
        <div className="text-sm text-gray-500">
          {applications.length} total applications
        </div>
      </div>

      {/* Filter Section */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center gap-4">
          <FilterIcon className="h-5 w-5 text-gray-400" />
          <div className="flex gap-2">
            <button
              onClick={() => setFilter('all')}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                filter === 'all' 
                  ? 'bg-blue-600 text-white' 
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              All
            </button>
            <button
              onClick={() => setFilter('applied')}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                filter === 'applied' 
                  ? 'bg-blue-600 text-white' 
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              Applied
            </button>
            <button
              onClick={() => setFilter('review')}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                filter === 'review' 
                  ? 'bg-blue-600 text-white' 
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              Under Review
            </button>
            <button
              onClick={() => setFilter('interview')}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                filter === 'interview' 
                  ? 'bg-blue-600 text-white' 
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              Interviews
            </button>
          </div>
        </div>
      </div>

      {/* Applications List */}
      <div className="grid gap-6">
        {filteredApplications.map((app) => (
          <div key={app.id} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="flex flex-col sm:flex-row sm:justify-between sm:items-start gap-4">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-2">
                  <BuildingIcon className="h-5 w-5 text-blue-600" />
                  <h3 className="text-xl font-semibold text-gray-900">{app.position}</h3>
                </div>
                <p className="text-lg text-gray-700 mb-3">{app.company}</p>
                <div className="flex flex-wrap gap-4 text-sm text-gray-500 mb-3">
                  <div className="flex items-center gap-1">
                    <MapPinIcon className="h-4 w-4" />
                    {app.location}
                  </div>
                  <div className="flex items-center gap-1">
                    <CalendarIcon className="h-4 w-4" />
                    Applied: {new Date(app.appliedDate).toLocaleDateString()}
                  </div>
                </div>
                <p className="text-sm text-gray-600 mb-2">
                  <span className="font-medium">Next step:</span> {app.nextStep}
                </p>
                <p className="text-sm text-gray-600">
                  <span className="font-medium">Salary:</span> {app.salary}
                </p>
              </div>
              <div className="flex flex-col gap-2 sm:ml-6">
                <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(app.status)}`}>
                  {getStatusText(app.status)}
                </span>
                <button className="bg-blue-600 text-white px-6 py-2 rounded-lg font-medium hover:bg-blue-700 transition-colors">
                  View Details
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default Applications;
