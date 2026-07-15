// EduLink Cloud Functions entrypoint.
// Import shared Admin SDK init once, then re-export each function.
import "./shared/admin";

export {health} from "./health";
export {completeRegistration} from "./auth/completeRegistration";
export {setRole} from "./auth/setRole";
export {submitCertification} from "./auth/submitCertification";
export {updateLocation} from "./profile/updateLocation";
export {addGalleryPhoto, removeGalleryPhoto} from "./profile/gallery";
export {setVideoLinks} from "./profile/setVideoLinks";
export {getCandidates} from "./swipe/getCandidates";
export {recordSwipe, getSwipeQuota} from "./swipe/recordSwipe";
export {placesAutocomplete} from "./places/placesAutocomplete";
export {placeDetails} from "./places/placeDetails";
export {onNewMessage} from "./notifications/onNewMessage";
export {markMatchRead} from "./matches/markMatchRead";
export {onVerificationChanged} from "./notifications/onVerificationChanged";
export {markNotificationsRead} from "./notifications/markNotificationsRead";
export {upsertJobCard, setJobCardStatus} from "./jobs/upsertJobCard";
export {getJobCards} from "./jobs/getJobCards";
export {applyToJob} from "./jobs/applyToJob";
export {
  resolveReport,
  approveTeacher,
  rejectTeacher,
  banUser,
  setFeatured,
  getCertificateUrls,
} from "./admin/adminActions";
export {sendUserEmail, sendBulkEmail, unsubscribe} from "./admin/email";
export {getQuotas, setQuotas} from "./admin/quotas";
export {revenuecatWebhook} from "./payments/revenuecatWebhook";
export {submitReview} from "./reviews/submitReview";
export {approveReview, rejectReview} from "./reviews/moderateReview";
export {onReviewWritten} from "./reviews/onReviewWritten";
export {reportUser} from "./safety/reportUser";
export {blockUser} from "./safety/blockUser";
