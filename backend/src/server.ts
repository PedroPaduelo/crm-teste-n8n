/**
 * Arquivo server.ts - Placeholder para teste de compilação
 * Este arquivo serve como ponto de entrada alternativo para o servidor
 * e será usado para testar se a configuração TypeScript está funcionando
 */

import express from 'express';
import cors from 'cors';

const app = express();
const PORT = process.env.PORT || 3002;

// Middleware
app.use(cors());
app.use(express.json());

// Rotas básicas para teste
app.get('/', (req, res) => {
  res.json({ 
    message: 'Servidor rodando via server.ts',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

app.get('/api/status', (req, res) => {
  res.json({
    status: 'OK',
    service: 'CRM Backend Server',
    port: PORT,
    uptime: process.uptime()
  });
});

// Rota para teste de compilação TypeScript
app.get('/api/test-typescript', (req, res) => {
  // Testando tipos TypeScript
  const testData: {
    message: string;
    typesWorking: boolean;
    timestamp: Date;
  } = {
    message: 'TypeScript compilation test successful!',
    typesWorking: true,
    timestamp: new Date()
  };
  
  res.json(testData);
});

// Iniciando servidor
app.listen(PORT, () => {
  console.log(`🚀 Servidor backend rodando na porta ${PORT} (via server.ts)`);
  console.log(`📊 Status do servidor disponível em: http://localhost:${PORT}/api/status`);
  console.log(`🧪 Teste TypeScript disponível em: http://localhost:${PORT}/api/test-typescript`);
  console.log(`💡 Este é um placeholder para teste de compilação TypeScript`);
});

export default app;