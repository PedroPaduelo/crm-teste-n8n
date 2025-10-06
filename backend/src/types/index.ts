// Tipos base para o CRM

export interface User {
  id: string;
  name: string;
  email: string;
  role: 'admin' | 'user' | 'manager';
  createdAt: Date;
  updatedAt: Date;
}

export interface Customer {
  id: string;
  name: string;
  email: string;
  phone?: string;
  company?: string;
  status: 'active' | 'inactive' | 'prospect';
  createdAt: Date;
  updatedAt: Date;
}

export interface Deal {
  id: string;
  customerId: string;
  title: string;
  value: number;
  status: 'lead' | 'contacted' | 'proposal' | 'negotiation' | 'closed-won' | 'closed-lost';
  stage: string;
  expectedCloseDate?: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface Task {
  id: string;
  title: string;
  description?: string;
  status: 'pending' | 'in-progress' | 'completed';
  priority: 'low' | 'medium' | 'high';
  assigneeId?: string;
  customerId?: string;
  dealId?: string;
  dueDate?: Date;
  createdAt: Date;
  updatedAt: Date;
}