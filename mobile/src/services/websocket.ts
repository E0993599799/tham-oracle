/**
 * 6F: WebSocket Client Service
 * Manages WebSocket connection to Phase 4 server
 * Handles connection lifecycle, reconnection, message queuing
 */

import { EventEmitter } from 'events';

export interface Proof {
  task_id: string;
  routed_lane: string;
  status: 'SUCCESS' | 'BLOCKED' | 'TIMEOUT' | 'ERROR';
  timestamp: string;
  execution_duration_seconds: number;
  risk_level?: string;
  intent_signal?: string;
}

export enum ConnectionState {
  CONNECTING = 'connecting',
  CONNECTED = 'connected',
  RECONNECTING = 'reconnecting',
  DISCONNECTED = 'disconnected',
  ERROR = 'error'
}

interface QueuedMessage {
  type: string;
  payload: any;
  timestamp: number;
}

export class WebSocketClient extends EventEmitter {
  private ws: WebSocket | null = null;
  private url: string;
  private state: ConnectionState = ConnectionState.DISCONNECTED;
  private messageQueue: QueuedMessage[] = [];
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 10;
  private reconnectDelay = 1000; // ms
  private heartbeatInterval: NodeJS.Timeout | null = null;
  private connectionTimeout: NodeJS.Timeout | null = null;

  constructor(url: string = 'ws://localhost:8765') {
    super();
    this.url = url;
  }

  public connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      if (this.state === ConnectionState.CONNECTED) {
        resolve();
        return;
      }

      this.setState(ConnectionState.CONNECTING);

      try {
        this.ws = new WebSocket(this.url);

        this.ws.onopen = () => {
          console.log('[WebSocket] Connected');
          this.reconnectAttempts = 0;
          this.setState(ConnectionState.CONNECTED);
          this.startHeartbeat();
          this.flushMessageQueue();
          this.emit('connect');
          resolve();
        };

        this.ws.onmessage = (event) => {
          try {
            const proof: Proof = JSON.parse(event.data);
            this.emit('proof', proof);
          } catch (e) {
            console.error('[WebSocket] Failed to parse proof:', e);
          }
        };

        this.ws.onerror = (event) => {
          console.error('[WebSocket] Error:', event);
          this.setState(ConnectionState.ERROR);
          this.emit('error', event);
          reject(event);
        };

        this.ws.onclose = () => {
          console.log('[WebSocket] Closed');
          this.setState(ConnectionState.DISCONNECTED);
          this.stopHeartbeat();
          this.emit('disconnect');
          this.attemptReconnect();
        };

        // Set connection timeout
        this.connectionTimeout = setTimeout(() => {
          if (this.state === ConnectionState.CONNECTING) {
            this.ws?.close();
            reject(new Error('Connection timeout'));
          }
        }, 10000);
      } catch (error) {
        this.setState(ConnectionState.ERROR);
        this.emit('error', error);
        reject(error);
      }
    });
  }

  public disconnect(): void {
    this.reconnectAttempts = this.maxReconnectAttempts; // Prevent reconnection
    this.stopHeartbeat();
    if (this.connectionTimeout) clearTimeout(this.connectionTimeout);
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
    this.setState(ConnectionState.DISCONNECTED);
  }

  public isConnected(): boolean {
    return this.state === ConnectionState.CONNECTED;
  }

  public getState(): ConnectionState {
    return this.state;
  }

  public send(message: any): void {
    if (this.state === ConnectionState.CONNECTED && this.ws) {
      try {
        this.ws.send(JSON.stringify(message));
      } catch (error) {
        console.error('[WebSocket] Send error:', error);
        this.queueMessage('command', message);
      }
    } else {
      this.queueMessage('command', message);
    }
  }

  private setState(state: ConnectionState): void {
    if (this.state !== state) {
      this.state = state;
      this.emit('stateChange', state);
    }
  }

  private startHeartbeat(): void {
    this.stopHeartbeat();
    this.heartbeatInterval = setInterval(() => {
      if (this.ws && this.state === ConnectionState.CONNECTED) {
        try {
          this.ws.send(JSON.stringify({ type: 'ping' }));
        } catch (error) {
          console.error('[WebSocket] Heartbeat error:', error);
        }
      }
    }, 30000); // 30 seconds
  }

  private stopHeartbeat(): void {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
      this.heartbeatInterval = null;
    }
  }

  private attemptReconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.log('[WebSocket] Max reconnection attempts reached');
      this.setState(ConnectionState.ERROR);
      return;
    }

    this.reconnectAttempts++;
    const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts - 1), 60000);
    console.log(`[WebSocket] Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`);

    this.setState(ConnectionState.RECONNECTING);
    setTimeout(() => {
      this.connect().catch((error) => {
        console.error('[WebSocket] Reconnection failed:', error);
      });
    }, delay);
  }

  private queueMessage(type: string, payload: any): void {
    this.messageQueue.push({
      type,
      payload,
      timestamp: Date.now()
    });
  }

  private flushMessageQueue(): void {
    while (this.messageQueue.length > 0) {
      const msg = this.messageQueue.shift();
      if (msg && this.ws && this.state === ConnectionState.CONNECTED) {
        try {
          this.ws.send(JSON.stringify(msg));
        } catch (error) {
          console.error('[WebSocket] Failed to send queued message:', error);
          this.messageQueue.unshift(msg);
          break;
        }
      }
    }
  }

  public getQueueSize(): number {
    return this.messageQueue.length;
  }
}

// Singleton instance
let instance: WebSocketClient | null = null;

export function getWebSocketClient(url?: string): WebSocketClient {
  if (!instance) {
    instance = new WebSocketClient(url);
  }
  return instance;
}

export function resetWebSocketClient(): void {
  if (instance) {
    instance.disconnect();
    instance = null;
  }
}
