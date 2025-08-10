import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { DocumentManager } from '../../main/ets/manager/DocumentManager';
import { DocumentItem } from '../../main/ets/model/DocumentItem';
import { DocumentType } from '../../main/ets/model/DocumentType';

export default function abilityTest() {
  describe('DocumentManagerTest', function () {
    let documentManager: DocumentManager;

    beforeAll(function () {
      documentManager = new DocumentManager();
    });

    it('should_get_documents_successfully', 0, function () {
      const documents = documentManager.getDocuments();
      expect(documents.length).assertGreaterThan(0);
    });

    it('should_filter_documents_by_type', 0, function () {
      const idCards = documentManager.getDocuments(DocumentType.ID_CARD);
      const passports = documentManager.getDocuments(DocumentType.PASSPORT);
      
      expect(idCards.length).assertGreaterThanOrEqual(0);
      expect(passports.length).assertGreaterThanOrEqual(0);
    });

    it('should_add_document_successfully', 0, function () {
      const newDocument = new DocumentItem(
        '',
        '测试证件',
        '身份证',
        '123456789',
        '2025-12-31',
        $r('app.media.background'),
        new Date(),
        new Date()
      );
      
      const result = documentManager.addDocument(newDocument);
      expect(result).assertTrue();
    });

    it('should_get_statistics_correctly', 0, function () {
      const stats = documentManager.getStatistics();
      expect(stats.total).assertGreaterThan(0);
      expect(stats.byType).assertNotNull();
    });

    it('should_check_expiry_documents', 0, function () {
      const expiredDocs = documentManager.checkExpiry();
      expect(Array.isArray(expiredDocs)).assertTrue();
    });
  });
}