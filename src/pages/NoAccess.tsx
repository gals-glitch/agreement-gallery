import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { useAuth } from '@/hooks/useAuth';
import { ShieldX, Home, Mail } from 'lucide-react';

export default function NoAccess() {
  const { profile, roles } = useAuth();

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <Card className="w-full max-w-md text-center">
        <CardHeader>
          <div className="mx-auto w-12 h-12 bg-destructive/10 rounded-full flex items-center justify-center mb-4">
            <ShieldX className="w-6 h-6 text-destructive" />
          </div>
          <CardTitle className="text-xl">Access Restricted</CardTitle>
          <CardDescription>
            You don't have the required permissions to access this page.
          </CardDescription>
        </CardHeader>
        
        <CardContent className="space-y-4">
          {profile && (
            <div className="bg-muted/50 rounded-lg p-3 text-sm">
              <p><strong>Account:</strong> {profile.display_name || profile.email}</p>
              <p><strong>Current Roles:</strong> {roles.length > 0 ? roles.join(', ') : 'No roles assigned'}</p>
            </div>
          )}
          
          <div className="space-y-2">
            <p className="text-sm text-muted-foreground">
              Contact your administrator to request access to this feature.
            </p>
            
            <div className="flex flex-col gap-2 mt-4">
              <Button asChild variant="default">
                <a href="/">
                  <Home className="w-4 h-4 mr-2" />
                  Return to Dashboard
                </a>
              </Button>
              
              <Button asChild variant="outline">
                <a href="mailto:admin@company.com?subject=Access Request">
                  <Mail className="w-4 h-4 mr-2" />
                  Contact Administrator
                </a>
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}