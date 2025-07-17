import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';

const CompanyDetails = () => {
  const { id } = useParams();
  const [company, setCompany] = useState(null);

  useEffect(() => {
    // TODO: Fetch company details by ID
    // Example stub:
    setCompany({
      name: `Company ${id}`,
      description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      location: 'City, Country',
      website: 'https://example.com',
    });
  }, [id]);

  if (!company) return <div>Loading company data...</div>;

  return (
    <div className="py-8 bg-gray-50 min-h-screen">
      <div className="max-w-3xl mx-auto p-4 bg-white rounded shadow">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">{company.name}</h1>
        <p className="text-gray-700 mb-4">{company.description}</p>
        <p className="text-gray-600 mb-2"><strong>Location:</strong> {company.location}</p>
        <p className="text-gray-600 mb-4"><strong>Website:</strong> <a href={company.website} className="text-blue-600 hover:underline">{company.website}</a></p>
        {/* TODO: Add more details like open positions */}
      </div>
    </div>
  );
};

export default CompanyDetails;
