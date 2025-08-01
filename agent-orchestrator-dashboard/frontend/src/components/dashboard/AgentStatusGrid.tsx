import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Badge } from '../ui/badge';
import { Card } from '../ui/card';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '../ui/tooltip';
import { useSocket } from '../../contexts/socket-context';
import { api } from '../../lib/api';
import { cn } from '../../lib/utils';

interface Agent {
  name: string;
  category: string;
  status: 'idle' | 'running' | 'error' | 'offline';
  lastSeen: string;
  currentExecution?: string;
  metrics: {
    totalExecutions: number;
    successRate: number;
    avgExecutionTime: number;
  };
}

export function AgentStatusGrid() {
  const { subscribe, unsubscribe, emit } = useSocket();
  const [agents, setAgents] = useState<Agent[]>([]);

  const { data: initialAgents } = useQuery({
    queryKey: ['agents'],
    queryFn: () => api.get('/agents').then(res => res.data),
  });

  useEffect(() => {
    if (initialAgents) {
      setAgents(initialAgents);
    }
  }, [initialAgents]);

  useEffect(() => {
    // Subscribe to all agent updates
    const handleAgentStatus = (data: any) => {
      setAgents(prev => prev.map(agent => 
        agent.name === data.agentName 
          ? { ...agent, ...data.status }
          : agent
      ));
    };

    agents.forEach(agent => {
      emit('subscribe:agent', agent.name);
    });

    subscribe('agent:status', handleAgentStatus);

    return () => {
      agents.forEach(agent => {
        emit('unsubscribe:agent', agent.name);
      });
      unsubscribe('agent:status', handleAgentStatus);
    };
  }, [agents.length]);

  const categories = [...new Set(agents.map(a => a.category))];

  return (
    <div className="space-y-6">
      {categories.map(category => (
        <div key={category}>
          <h3 className="text-sm font-medium text-muted-foreground mb-3 capitalize">
            {category}
          </h3>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
            {agents
              .filter(agent => agent.category === category)
              .map(agent => (
                <AgentCard key={agent.name} agent={agent} />
              ))}
          </div>
        </div>
      ))}
    </div>
  );
}

function AgentCard({ agent }: { agent: Agent }) {
  const statusColors = {
    idle: 'bg-gray-500',
    running: 'bg-green-500',
    error: 'bg-red-500',
    offline: 'bg-gray-300',
  };

  const formatAgentName = (name: string) => {
    return name
      .split('-')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  };

  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <Card className="p-3 cursor-pointer hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <div className={cn(
                  'w-2 h-2 rounded-full animate-pulse',
                  statusColors[agent.status]
                )} />
                <span className="text-sm font-medium truncate">
                  {formatAgentName(agent.name)}
                </span>
              </div>
              <Badge variant={agent.status === 'running' ? 'default' : 'secondary'} className="text-xs">
                {agent.status}
              </Badge>
            </div>
            <div className="text-xs text-muted-foreground space-y-1">
              <div className="flex justify-between">
                <span>Executions:</span>
                <span>{agent.metrics.totalExecutions}</span>
              </div>
              <div className="flex justify-between">
                <span>Success:</span>
                <span>{agent.metrics.successRate.toFixed(0)}%</span>
              </div>
            </div>
          </Card>
        </TooltipTrigger>
        <TooltipContent>
          <div className="space-y-2">
            <p className="font-semibold">{formatAgentName(agent.name)}</p>
            <p className="text-sm">Category: {agent.category}</p>
            <p className="text-sm">Last seen: {new Date(agent.lastSeen).toLocaleString()}</p>
            {agent.currentExecution && (
              <p className="text-sm">Current execution: {agent.currentExecution}</p>
            )}
            <p className="text-sm">
              Avg time: {(agent.metrics.avgExecutionTime / 60).toFixed(1)} min
            </p>
          </div>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}