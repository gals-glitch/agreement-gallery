import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import { useNavigate } from "react-router-dom";
import PartyManagement from "@/components/PartyManagement";


export default function PartyManagementPage() {
  const navigate = useNavigate();

  return (
    <div className="container mx-auto py-6 space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="sm" onClick={() => navigate('/')}>
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back
        </Button>
        <div>
          <h1 className="text-3xl font-bold">Party Management</h1>
          <p className="text-muted-foreground">
            Manage distributors and partner relationships
          </p>
        </div>
      </div>

      <PartyManagement />
    </div>
  );
}
