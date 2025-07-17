import { useState } from 'react';
import { BriefcaseIcon, MapPinIcon, CalendarIcon, DollarSignIcon, SearchIcon } from 'lucide-react';

const Jobs = () => {
  const [searchTerm, setSearchTerm] = useState('');
  
  const jobs = [
    {
      id: 1,
      title: 'Senior Software Developer',
      company: 'TechCorp SA',
      location: 'Cape Town, Western Cape',
      salary: 'R60,000 - R80,000',
      type: 'Full-time',
      posted: '2 days ago'
    },
    {
      id: 2,
      title: 'Frontend Developer',
      company: 'Digital Solutions',
      location: 'Johannesburg, Gauteng',
      salary: 'R45,000 - R65,000',
      type: 'Full-time',
      posted: '1 week ago'
    }
  ];

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-900">Available Jobs</h1>
      <div className="grid gap-6">
        {jobs.map((job) => (
          <div key={job.id} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 className="text-xl font-semibold text-gray-900 mb-2">{job.title}</h3>
            <p className="text-lg text-gray-700 mb-3">{job.company}</p>
            <p className="text-gray-600 mb-3">{job.location}</p>
            <p className="text-gray-600 mb-4">{job.salary}</p>
            <button className="bg-blue-600 text-white px-6 py-2 rounded-lg font-medium hover:bg-blue-700 transition-colors">
              Apply Now
            </button>
          </div>
        ))}
      </div>
    </div>
  );
};

export default Jobs;