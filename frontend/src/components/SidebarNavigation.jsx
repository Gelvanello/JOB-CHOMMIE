import {
  Sidebar,
  SidebarProvider,
  SidebarContent,
  SidebarMenu,
  SidebarMenuItem,
  SidebarMenuButton,
} from '@/components/ui/sidebar';
import { Link, useLocation } from 'react-router-dom';
import {
  HomeIcon,
  BriefcaseIcon,
  ListIcon,
  UserIcon,
  CreditCardIcon,
} from 'lucide-react';

const SidebarNavigation = () => {
  const location = useLocation();

  const links = [
    { label: 'Dashboard', href: '/dashboard', icon: <HomeIcon className="w-4 h-4" /> },
    { label: 'Jobs', href: '/jobs', icon: <BriefcaseIcon className="w-4 h-4" /> },
    { label: 'Applications', href: '/applications', icon: <ListIcon className="w-4 h-4" /> },
    { label: 'Profile', href: '/profile', icon: <UserIcon className="w-4 h-4" /> },
    { label: 'Subscription', href: '/subscription', icon: <CreditCardIcon className="w-4 h-4" /> },
  ];

  return (
    <SidebarProvider defaultOpen={true}>
      <Sidebar className="fixed left-0 top-16 h-[calc(100vh-4rem)] w-64 bg-white border-r border-gray-200 shadow-sm">
        <SidebarContent className="p-4">
          <SidebarMenu className="space-y-2">
            {links.map(({ label, href, icon }) => (
              <SidebarMenuItem key={href}>
                <SidebarMenuButton
                  asChild
                  isActive={location.pathname === href}
                  className={`w-full flex items-center gap-3 px-3 py-2 text-sm font-medium rounded-lg transition-colors ${
                    location.pathname === href
                      ? 'bg-blue-50 text-blue-700 border-l-4 border-blue-700'
                      : 'text-gray-700 hover:bg-gray-50 hover:text-gray-900'
                  }`}
                >
                  <Link to={href} className="flex items-center gap-3 w-full">
                    {icon}
                    {label}
                  </Link>
                </SidebarMenuButton>
              </SidebarMenuItem>
            ))}
          </SidebarMenu>
        </SidebarContent>
      </Sidebar>
    </SidebarProvider>
  );
};

export default SidebarNavigation;
