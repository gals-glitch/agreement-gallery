/**
 * Fund VI Tracks Configuration Page
 */

import { FundVITracksAdmin } from '@/components/FundVITracksAdmin';
import { SidebarProvider, SidebarTrigger } from '@/components/ui/sidebar';
import { AppSidebar } from '@/components/AppSidebar';
import { Button } from '@/components/ui/button';
import { ArrowLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';


export default function FundVITracksPage() {
  const navigate = useNavigate();

  return (
    <SidebarProvider>
      <div className="min-h-screen w-full flex bg-background">
        <AppSidebar />
        
        <div className="flex-1 flex flex-col">
          <div className="sticky top-0 z-20 bg-background/80 backdrop-blur border-b border-border">
            <div className="px-4 py-3 flex items-center gap-3">
              <SidebarTrigger />
              <Button variant="ghost" size="sm" onClick={() => navigate('/')}>
                <ArrowLeft className="w-4 h-4 mr-2" />
                Back
              </Button>
              <h1 className="text-lg font-semibold">Fund VI Tracks</h1>
            </div>
          </div>

          <main className="flex-1">
            <FundVITracksAdmin />
          </main>
        </div>
      </div>
    </SidebarProvider>
  );
}
