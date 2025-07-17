import { Outlet } from 'react-router-dom';
import Navbar from './Navbar';
import SidebarNavigation from '../SidebarNavigation';

function Layout() {
  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="flex">
        <SidebarNavigation />
        <main className="flex-1 p-6 ml-64">
          <div className="max-w-7xl mx-auto">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}

export default Layout;
