"""
MinIO Storage Backend per Saleor
Storage backend ottimizzato per MinIO
"""
import os
from django.conf import settings
from django.core.files.storage import Storage
from django.utils.deconstruct import deconstructible
from minio import Minio
from minio.error import S3Error
import logging

logger = logging.getLogger(__name__)


@deconstructible
class MinIOStorage(Storage):
    """
    Storage backend personalizzato per MinIO
    Compatibile con l'API di Django Storage
    """
    
    def __init__(self, bucket_name=None, endpoint=None, access_key=None, secret_key=None, secure=None):
        """
        Inizializza il client MinIO con le configurazioni
        """
        self.bucket_name = bucket_name or getattr(settings, 'MINIO_MEDIA_BUCKET_NAME', 'saleor-media')
        self.endpoint = endpoint or getattr(settings, 'MINIO_ENDPOINT', 'localhost')
        self.access_key = access_key or getattr(settings, 'MINIO_ACCESS_KEY', 'minioadmin')
        self.secret_key = secret_key or getattr(settings, 'MINIO_SECRET_KEY', 'minioadmin123')
        self.secure = secure if secure is not None else getattr(settings, 'MINIO_USE_SSL', False)
        
        # Inizializza il client MinIO
        # Debug logging
        print(f"DEBUG: MinIO endpoint originale: {self.endpoint}")
        print(f"DEBUG: MinIO endpoint tipo: {type(self.endpoint)}")
        print(f"DEBUG: MinIO endpoint repr: {repr(self.endpoint)}")
        
        self.client = Minio(
            endpoint=self.endpoint,
            access_key=self.access_key,
            secret_key=self.secret_key,
            secure=self.secure
        )
        
        # Crea il bucket se non esiste
        self._ensure_bucket_exists()
    
    def _ensure_bucket_exists(self):
        """
        Crea il bucket se non esiste
        """
        try:
            if not self.client.bucket_exists(self.bucket_name):
                self.client.make_bucket(self.bucket_name)
                logger.info(f"Bucket '{self.bucket_name}' creato con successo")
        except S3Error as e:
            logger.error(f"Errore nella creazione del bucket '{self.bucket_name}': {e}")
            raise
    
    def _open(self, name, mode='rb'):
        """
        Apre un file dal storage MinIO
        """
        try:
            response = self.client.get_object(self.bucket_name, name)
            return response
        except S3Error as e:
            logger.error(f"Errore nell'apertura del file '{name}': {e}")
            raise
    
    def _save(self, name, content):
        """
        Salva un file nel storage MinIO
        """
        try:
            # Leggi il contenuto del file
            content.seek(0)
            data = content.read()
            
            # Salva nel bucket MinIO
            self.client.put_object(
                bucket_name=self.bucket_name,
                object_name=name,
                data=data,
                length=len(data),
                content_type=getattr(content, 'content_type', 'application/octet-stream')
            )
            
            logger.info(f"File '{name}' salvato con successo nel bucket '{self.bucket_name}'")
            return name
        except S3Error as e:
            logger.error(f"Errore nel salvataggio del file '{name}': {e}")
            raise
    
    def delete(self, name):
        """
        Elimina un file dal storage MinIO
        """
        try:
            self.client.remove_object(self.bucket_name, name)
            logger.info(f"File '{name}' eliminato con successo")
        except S3Error as e:
            logger.error(f"Errore nell'eliminazione del file '{name}': {e}")
            raise
    
    def exists(self, name):
        """
        Verifica se un file esiste nel storage MinIO
        """
        try:
            self.client.stat_object(self.bucket_name, name)
            return True
        except S3Error:
            return False
    
    
    
    def url(self, name):
        """
        Restituisce l'URL pubblico del file
        """
        # Usa il custom domain se configurato
        custom_domain = getattr(settings, 'MINIO_MEDIA_CUSTOM_DOMAIN', None)
        if custom_domain:
            protocol = "https" if getattr(settings, 'MINIO_USE_SSL', False) else "http"
            return f"{protocol}://{custom_domain}/{self.bucket_name}/{name}"
        
        # URL standard MinIO per sviluppo
        protocol = "https" if self.secure else "http"
        port = "9001" if not self.secure else "9000"
        return f"{protocol}://{self.endpoint}:{port}/{self.bucket_name}/{name}"
    
    def get_available_name(self, name, max_length=None):
        """
        Restituisce un nome disponibile per il file
        """
        if not self.exists(name):
            return name
        
        # Genera un nome unico semplice
        name, ext = os.path.splitext(name)
        import time
        return f"{name}_{int(time.time())}{ext}"
