import {DroneExport} from '@core/@types/entity-exports';
import {SharedQueue} from '@core/@types/shared-queue';
import config from 'config';

/**
 * Disconnects a drone from the server.
 *
 * @export
 * @param {{
 *   sharedQueue: SharedQueue,
 *   connectedDronesList: Array<DroneExport>,
 * }} {
 *   sharedQueue,
 *   connectedDronesList,
 * } - dependency injection
 * @return {Function} - drone disconnection function
 */
export default function buildDisconnectDrone({
  sharedQueue,
  connectedDronesList,
}: {
    sharedQueue: SharedQueue;
    connectedDronesList: Array<DroneExport>;
  }): Function {
  return async function disconnectDrone(ip: string) {
    // Emitting an 'DRONE_NOTFOUND' event in shared queue on invalid request
    try {
      // Verifying whether the drone is connected
      if (connectedDronesList.find((i) => i.getSource().getIp() === ip)) {
        throw new Error('Drone is already connected.');
      }

      // Deleting drone from connected list
      delete connectedDronesList.filter(
          (item) => item.getSource().getIp() === ip,
      )[0];
    } catch (e) {
      sharedQueue.emit([
        config.get('INBOUND_LOGGER_SERVICE_QUEUE'),
      ], {
        subject: 'DRONE_NOTFOUND',
        body: {error: e.message},
      });
      throw e;
    }

    // Notifying the logger service on success
    sharedQueue.emit([
      config.get('INBOUND_LOGGER_SERVICE_QUEUE'),
    ], {
      subject: 'DRONE_DISCONNECTED',
      body: {ip: ip},
    });
  };
}
