import { NavLink, useLocation } from "react-router-dom";
import {
  Building2,
  LogOut,
  User,
  Sparkles,
  DollarSign,
  Database,
  Workflow,
  Shield,
  Flag,
  Receipt,
  Users,
  TrendingUp,
  FileText
} from "lucide-react";
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  useSidebar,
} from "@/components/ui/sidebar";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { useAuth } from "@/hooks/useAuth";
import { useFeatureFlag } from "@/hooks/useFeatureFlags";

// DATA section
const dataItems = [
  {
    title: "Parties",
    url: "/parties",
    icon: Building2,
    description: "Distributors & partners"
  },
  {
    title: "Investors",
    url: "/investors",
    icon: Users,
    description: "Investor management"
  },
  {
    title: "Contributions",
    url: "/contributions",
    icon: DollarSign,
    description: "Track paid-in capital"
  },
];

// WORKFLOW section
const workflowItems = [
  {
    title: "Commissions",
    url: "/commissions",
    icon: TrendingUp,
    description: "Distributor commission workflow",
    featureFlag: "commissions_engine"
  },
  {
    title: "Agreements",
    url: "/agreements",
    icon: FileText,
    description: "Commission agreements & terms"
  },
];

// ADMIN section (admin-only)
const adminItems = [
  {
    title: "Feature Flags",
    url: "/admin/feature-flags",
    icon: Flag,
    description: "Toggle features"
  },
  {
    title: "VAT Settings",
    url: "/vat-settings",
    icon: Receipt,
    description: "VAT rate configuration",
    featureFlag: "vat_admin"
  },
];


/**
 * Helper component to render a menu item with optional feature flag guard
 */
function SidebarNavItem({
  item,
  state,
  getNavClass
}: {
  item: any;
  state: string;
  getNavClass: (props: { isActive: boolean }) => string;
}) {
  const { isEnabled } = useFeatureFlag(item.featureFlag || '');

  // If feature flag is specified and not enabled, don't render
  if (item.featureFlag && !isEnabled) {
    return null;
  }

  return (
    <SidebarMenuItem key={item.url}>
      <SidebarMenuButton asChild>
        <NavLink
          to={item.url}
          end={item.url === "/"}
          className={({ isActive }) =>
            `${getNavClass({ isActive })} h-auto py-3 px-3 flex items-center`
          }
          title={state === "collapsed" ? item.title : undefined}
        >
          <item.icon className="h-5 w-5 flex-shrink-0" />
          {state !== "collapsed" && (
            <div className="flex-1 min-w-0 ml-3">
              <span className="block truncate font-medium">{item.title}</span>
              <span className="text-xs text-muted-foreground block truncate mt-0.5">
                {item.description}
              </span>
            </div>
          )}
        </NavLink>
      </SidebarMenuButton>
    </SidebarMenuItem>
  );
}

export function AppSidebar() {
  const { state } = useSidebar();
  const { user, signOut, isAdmin } = useAuth();
  const location = useLocation();

  const getNavClass = ({ isActive }: { isActive: boolean }) =>
    isActive
      ? "bg-primary text-primary-foreground font-medium"
      : "hover:bg-accent hover:text-accent-foreground";

  return (
    <Sidebar className={state === "collapsed" ? "w-14" : "w-64"}>
      <SidebarContent className="bg-background">
        {/* Header */}
        <div className="p-4 border-b">
          <div className="flex items-center gap-2">
            <Sparkles className="w-6 h-6 text-primary flex-shrink-0" />
            {state !== "collapsed" && (
              <div className="flex-1 min-w-0">
                <h1 className="font-semibold text-sm leading-tight">
                  Buligo Compensation
                </h1>
                <Badge variant="secondary" className="mt-1 text-xs">
                  Fund VI MVP
                </Badge>
              </div>
            )}
          </div>
        </div>

        {/* DATA Section */}
        <SidebarGroup className="px-2">
          <SidebarGroupLabel className="px-2 py-2">
            <Database className="w-4 h-4 mr-2 inline" />
            {state !== "collapsed" && "DATA"}
          </SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu className="space-y-2">
              {dataItems.map((item) => (
                <SidebarNavItem
                  key={item.url}
                  item={item}
                  state={state}
                  getNavClass={getNavClass}
                />
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>

        {/* WORKFLOW Section */}
        <SidebarGroup className="px-2">
          <SidebarGroupLabel className="px-2 py-2">
            <Workflow className="w-4 h-4 mr-2 inline" />
            {state !== "collapsed" && "WORKFLOW"}
          </SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu className="space-y-2">
              {workflowItems.map((item) => (
                <SidebarNavItem
                  key={item.url}
                  item={item}
                  state={state}
                  getNavClass={getNavClass}
                />
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>

        {/* ADMIN Section (admin-only) */}
        {isAdmin() && (
          <SidebarGroup className="px-2">
            <SidebarGroupLabel className="px-2 py-2">
              <Shield className="w-4 h-4 mr-2 inline" />
              {state !== "collapsed" && "ADMIN"}
            </SidebarGroupLabel>
            <SidebarGroupContent>
              <SidebarMenu className="space-y-2">
                {adminItems.map((item) => (
                  <SidebarNavItem
                    key={item.url}
                    item={item}
                    state={state}
                    getNavClass={getNavClass}
                  />
                ))}
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>
        )}

        {/* User Section */}
        <div className="mt-auto p-4 border-t">
          {state !== "collapsed" ? (
            <div className="space-y-3">
              <div className="flex items-center gap-2 text-sm">
                <User className="w-4 h-4 flex-shrink-0" />
                <span className="truncate">{user?.email}</span>
              </div>
              <Button
                variant="outline"
                size="sm"
                onClick={signOut}
                className="w-full gap-2"
              >
                <LogOut className="w-4 h-4" />
                Sign Out
              </Button>
            </div>
          ) : (
            <div className="flex flex-col gap-2">
              <Button
                variant="ghost"
                size="sm"
                className="w-full p-2"
                title="User Account"
              >
                <User className="w-4 h-4" />
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={signOut}
                className="w-full p-2"
                title="Sign Out"
              >
                <LogOut className="w-4 h-4" />
              </Button>
            </div>
          )}
        </div>
      </SidebarContent>
    </Sidebar>
  );
}
