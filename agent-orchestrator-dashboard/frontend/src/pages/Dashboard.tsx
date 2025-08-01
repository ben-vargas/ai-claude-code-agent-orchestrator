import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { AgentStatusGrid } from '../components/dashboard/AgentStatusGrid';
import { ExecutionMetrics } from '../components/dashboard/ExecutionMetrics';
import { RecentActivity } from '../components/dashboard/RecentActivity';
import { SystemHealth } from '../components/dashboard/SystemHealth';
import { useSocket } from '../contexts/socket-context';
import { api } from '../lib/api';

export default function DashboardPage() {
  const { subscribe, unsubscribe } = useSocket();
  const [realtimeMetrics, setRealtimeMetrics] = useState<any>({});

  const { data: dashboardData, isLoading } = useQuery({
    queryKey: ['dashboard'],
    queryFn: () => api.get('/dashboard').then(res => res.data),
    refetchInterval: 30000, // Refresh every 30 seconds
  });

  useEffect(() => {
    const handleMetricUpdate = (data: any) => {
      setRealtimeMetrics(prev => ({
        ...prev,
        [data.metricName]: data.metricValue,
      }));
    };

    subscribe('metric:update', handleMetricUpdate);
    return () => unsubscribe('metric:update', handleMetricUpdate);
  }, [subscribe, unsubscribe]);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
        <p className="text-muted-foreground">
          Real-time overview of your agent orchestration system
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Projects</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{dashboardData?.projectCount || 0}</div>
            <p className="text-xs text-muted-foreground">
              {dashboardData?.activeProjects || 0} active
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Running Agents</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{realtimeMetrics.runningAgents || 0}</div>
            <p className="text-xs text-muted-foreground">
              of {dashboardData?.totalAgents || 24} total
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Success Rate</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {dashboardData?.successRate?.toFixed(1) || 0}%
            </div>
            <p className="text-xs text-muted-foreground">
              Last 24 hours
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Avg Execution Time</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {formatDuration(dashboardData?.avgExecutionTime || 0)}
            </div>
            <p className="text-xs text-muted-foreground">
              Per agent task
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-7">
        <Card className="col-span-4">
          <CardHeader>
            <CardTitle>Agent Status</CardTitle>
            <CardDescription>Real-time status of all agents</CardDescription>
          </CardHeader>
          <CardContent>
            <AgentStatusGrid />
          </CardContent>
        </Card>

        <Card className="col-span-3">
          <CardHeader>
            <CardTitle>System Health</CardTitle>
            <CardDescription>Resource utilization and performance</CardDescription>
          </CardHeader>
          <CardContent>
            <SystemHealth />
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Execution Metrics</CardTitle>
            <CardDescription>Performance trends over time</CardDescription>
          </CardHeader>
          <CardContent>
            <ExecutionMetrics />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Recent Activity</CardTitle>
            <CardDescription>Latest agent executions and events</CardDescription>
          </CardHeader>
          <CardContent>
            <RecentActivity />
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function formatDuration(seconds: number): string {
  if (seconds < 60) return `${seconds.toFixed(0)}s`;
  if (seconds < 3600) return `${(seconds / 60).toFixed(0)}m`;
  return `${(seconds / 3600).toFixed(1)}h`;
}