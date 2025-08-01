import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Toaster } from './components/ui/toaster';
import { ThemeProvider } from './components/theme-provider';
import { AuthProvider } from './contexts/auth-context';
import { SocketProvider } from './contexts/socket-context';

import Layout from './components/Layout';
import LoginPage from './pages/Login';
import DashboardPage from './pages/Dashboard';
import ProjectsPage from './pages/Projects';
import AgentsPage from './pages/Agents';
import ExecutionsPage from './pages/Executions';
import ConfigurationPage from './pages/Configuration';
import FlowVisualizerPage from './pages/FlowVisualizer';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5000,
      refetchOnWindowFocus: false,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider defaultTheme="system" storageKey="orchestrator-theme">
        <AuthProvider>
          <SocketProvider>
            <Router>
              <Routes>
                <Route path="/login" element={<LoginPage />} />
                <Route path="/" element={<Layout />}>
                  <Route index element={<Navigate to="/dashboard" replace />} />
                  <Route path="dashboard" element={<DashboardPage />} />
                  <Route path="projects" element={<ProjectsPage />} />
                  <Route path="agents" element={<AgentsPage />} />
                  <Route path="executions" element={<ExecutionsPage />} />
                  <Route path="executions/:id" element={<FlowVisualizerPage />} />
                  <Route path="configuration" element={<ConfigurationPage />} />
                </Route>
              </Routes>
            </Router>
            <Toaster />
          </SocketProvider>
        </AuthProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

export default App;