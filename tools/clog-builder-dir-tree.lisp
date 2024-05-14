(in-package :clog-tools)

(defun on-dir-tree (obj &key dir)
  (let* ((*default-title-class*      *builder-title-class*)
         (*default-border-class*     *builder-border-class*)
         (win         (create-gui-window obj :title "Directory Tree"
                                         :width 300
                                         :has-pinner t
                                         :keep-on-top t
                                         :client-movement *client-side-movement*))
         (root-dir    (create-form-element (window-content win) :text))
         (tree       (create-panel (window-content win)
                                   :class "w3-small"
                                   :overflow :scroll
                                   :top 30 :bottom 0 :left 0 :right 0)))
    (set-geometry win :top (menu-bar-height win) :left 0 :height "" :bottom 5 :right "")
    (setf (positioning root-dir) :absolute)
    (set-geometry root-dir :height 27 :width "100%" :top 0 :left 0 :right 0)
    (setf (text-value root-dir) (format nil "~A" (or dir (uiop:getcwd))))
    (labels ((project-tree-dir-select (node dir)
               (dolist (item (sort (uiop:subdirectories dir)
                                   (lambda (a b)
                                     (string-lessp (format nil "~A" a) (format nil "~A" b)))))
                 (create-clog-tree (tree-root node)
                                   :fill-function (lambda (obj)
                                                    (project-tree-dir-select obj (format nil "~A" item)))
                                   :indent-level (1+ (indent-level node))
                                   :visible nil
                                   :on-context-menu
                                   (lambda (obj)
                                     (let* ((disp (text-value (content obj)))
                                            (menu (create-panel obj
                                                                :left (left obj) :top (top obj)
                                                                :width (width obj)
                                                                :class *builder-window-desktop-class*
                                                                :auto-place :top))
                                            (title (create-div menu :content disp))
                                            (op    (create-div menu :content "Toggle Open" :class *builder-menu-context-item-class*))
                                            (ops   (create-div menu :content "Open in Pseudo Shell" :class *builder-menu-context-item-class*))
                                            (opo   (create-div menu :content "Open in OS" :class *builder-menu-context-item-class*))
                                            (opd   (create-div menu :content "Open in new Tree" :class *builder-menu-context-item-class*))
                                            (opr   (create-div menu :content "Set as root" :class *builder-menu-context-item-class*))
                                            (nwd   (create-div menu :content "New subdirectory" :class *builder-menu-context-item-class*))
                                            (ren   (create-div menu :content "Rename Director" :class *builder-menu-context-item-class*))
                                            (del   (create-div menu :content "Delete Directory" :class *builder-menu-context-item-class*)))
                                       (declare (ignore title op))
                                       (set-on-click menu (lambda (i)
                                                            (declare (ignore i))
                                                            (destroy menu)))
                                       (set-on-click opd (lambda (i)
                                                           (declare (ignore i))
                                                           (on-dir-tree obj :dir item))
                                                     :cancel-event t)
                                       (set-on-click opr (lambda (i)
                                                           (declare (ignore i))
                                                           (setf (text-value root-dir) item)
                                                           (jquery-execute root-dir "trigger('change')"))
                                                     :cancel-event t)
                                       (set-on-click ops (lambda (i)
                                                           (declare (ignore i))
                                                           (on-shell obj :dir item))
                                                     :cancel-event t)
                                       (set-on-click opo (lambda (i)
                                                           (declare (ignore i))
                                                           (open-file-with-os item))
                                                     :cancel-event t)
                                       (set-on-click nwd (lambda (i)
                                                           (declare (ignore i))
                                                           (let* ((*default-title-class*      *builder-title-class*)
                                                                  (*default-border-class*     *builder-border-class*))
                                                             (input-dialog obj "Name of new directory?"
                                                                           (lambda (result)
                                                                             (when result
                                                                               (ensure-directories-exist (format nil "~A~A/" item result))
                                                                               (toggle-tree obj)
                                                                               (toggle-tree obj)))
                                                                           :title "New Directory")))
                                                     :cancel-event t)
                                       (set-on-click ren (lambda (i)
                                                           (declare (ignore i))
                                                           (let* ((*default-title-class*      *builder-title-class*)
                                                                  (*default-border-class*     *builder-border-class*))
                                                             (input-dialog obj (format nil "Rename ~A to?" disp)
                                                                           (lambda (result)
                                                                             (when result
                                                                               (rename-file item (format nil "~A~A/" dir result))
                                                                               (setf item (format nil "~A~A/" dir result))
                                                                               (setf (text-value (content obj)) result)))
                                                                           :title "Rename Directory")))
                                                     :cancel-event t)
                                       (set-on-click del (lambda (i)
                                                           (let* ((*default-title-class*      *builder-title-class*)
                                                                  (*default-border-class*     *builder-border-class*))
                                                             (confirm-dialog i (format nil "Delete ~A?" disp)
                                                                             (lambda (result)
                                                                               (when result
                                                                                 (handler-case
                                                                                     (progn
                                                                                       (uiop:delete-empty-directory item)
                                                                                       (destroy obj))
                                                                                   (error ()
                                                                                          (alert-toast obj "Directory Delete Failure"
                                                                                                       (format nil "Failed to delete ~A, perhaps not empty." item)))))))))
                                                     :cancel-event t)
                                       (set-on-mouse-leave menu (lambda (obj) (destroy obj)))))
                                   :content (first (last (pathname-directory item)))))
               (dolist (item (sort (uiop:directory-files (directory-namestring dir))
                                   (lambda (a b)
                                     (if (equal (pathname-name a) (pathname-name b))
                                         (string-lessp (format nil "~A" a)                                                       (format nil "~A" b))
                                         (string-lessp (format nil "~A" (pathname-name a))
                                                       (format nil "~A" (pathname-name b)))))))
                 (create-clog-tree-item (tree-root node)
                                        :on-context-menu
                                        (lambda (obj)
                                          (let* ((disp (text-value (content obj)))
                                                 (menu (create-panel obj
                                                                     :left (left obj) :top (top obj)
                                                                     :width (width obj)
                                                                     :class *builder-window-desktop-class*
                                                                     :auto-place :top))
                                                 (title (create-div menu :content disp))
                                                 (op    (create-div menu :content "Open" :class *builder-menu-context-item-class*))
                                                 (oph   (create-div menu :content "Open this tab" :class *builder-menu-context-item-class*))
                                                 (opt   (create-div menu :content "Open new tab" :class *builder-menu-context-item-class*))
                                                 (ope   (create-div menu :content "Open emacs" :class *builder-menu-context-item-class*))
                                                 (opo   (create-div menu :content "Open OS default" :class *builder-menu-context-item-class*))
                                                 (ren   (create-div menu :content "Rename" :class *builder-menu-context-item-class*))
                                                 (del   (create-div menu :content "Delete" :class *builder-menu-context-item-class*)))
                                            (declare (ignore title op))
                                            (set-on-click menu (lambda (i)
                                                                 (declare (ignore i))
                                                                 (destroy menu)))
                                            (set-on-click oph (lambda (i)
                                                                (declare (ignore i))
                                                                (project-tree-select obj (format nil "~A" item) :method :here))
                                                          :cancel-event t)
                                            (set-on-click opt (lambda (i)
                                                                (declare (ignore i))
                                                                (project-tree-select obj (format nil "~A" item) :method :tab))
                                                          :cancel-event t)
                                            (set-on-click ope (lambda (i)
                                                                (declare (ignore i))
                                                                (project-tree-select obj (format nil "~A" item) :method :emacs))
                                                          :cancel-event t)
                                            (set-on-click opo (lambda (i)
                                                                (declare (ignore i))
                                                                (open-file-with-os item))
                                                          :cancel-event t)
                                            (set-on-click ren (lambda (i)
                                                                (declare (ignore i))
                                                                (let* ((*default-title-class*      *builder-title-class*)
                                                                       (*default-border-class*     *builder-border-class*))
                                                                  (input-dialog obj (format nil "Rename ~A to?" disp)
                                                                                (lambda (result)
                                                                                  (when result
                                                                                    (rename-file item (format nil "~A~A" (directory-namestring item) result))
                                                                                    (setf item (format nil "~A~A" (directory-namestring item) result))
                                                                                    (setf (text-value (content obj)) result)))
                                                                                :title "Rename File")))
                                                          :cancel-event t)
                                            (set-on-click del (lambda (i)
                                                                (let* ((*default-title-class*      *builder-title-class*)
                                                                       (*default-border-class*     *builder-border-class*))
                                                                  (confirm-dialog i (format nil "Delete ~A?" disp)
                                                                                  (lambda (result)
                                                                                    (when result
                                                                                      (uiop:delete-file-if-exists item)
                                                                                      (destroy obj))))))
                                                          :cancel-event t)
                                            (set-on-mouse-leave menu (lambda (obj) (destroy obj)))))
                                        :on-click (lambda (obj)
                                                    (project-tree-select obj (format nil "~A" item)))
                                        :content (file-namestring item))))
             (on-change (obj)
               (declare (ignore obj))
               (setf (text tree) "")
               (let* ((root (text-value root-dir))
                      (tname (truename root))
                      (dir   (format nil "~A" (uiop:native-namestring (directory-namestring (if tname
                                                                        tname
                                                                        ""))))))
                 (setf (text-value root-dir) dir)
                 (create-clog-tree tree
                                   :fill-function (lambda (obj)
                                                    (project-tree-dir-select obj dir))
                                   :content dir
                                   :on-context-menu
                                   (lambda (obj)
                                     (let* ((disp dir)
                                            (item dir)
                                            (menu (create-panel obj
                                                                :left (left obj) :top (top obj)
                                                                :width (width obj)
                                                                :class *builder-window-desktop-class*
                                                                :auto-place :top))
                                            (title (create-div menu :content disp))
                                            (op    (create-div menu :content "Toggle Open" :class *builder-menu-context-item-class*))
                                            (ops   (create-div menu :content "Open Pseudo Shell" :class *builder-menu-context-item-class*))
                                            (opo   (create-div menu :content "Open in OS" :class *builder-menu-context-item-class*))
                                            (nwd   (create-div menu :content "New subdirectory" :class *builder-menu-context-item-class*)))
                                       (declare (ignore title op))
                                       (set-on-click menu (lambda (i)
                                                            (declare (ignore i))
                                                            (destroy menu)))
                                       (set-on-click ops (lambda (i)
                                                           (declare (ignore i))
                                                           (on-shell obj :dir item))
                                                     :cancel-event t)
                                       (set-on-click opo (lambda (i)
                                                           (declare (ignore i))
                                                           (open-file-with-os item))
                                                     :cancel-event t)
                                       (set-on-click nwd (lambda (i)
                                                           (declare (ignore i))
                                                           (let* ((*default-title-class*      *builder-title-class*)
                                                                  (*default-border-class*     *builder-border-class*))
                                                             (input-dialog obj "Name of new directory?"
                                                                           (lambda (result)
                                                                             (when result
                                                                               (ensure-directories-exist (format nil "~A~A/" dir result))
                                                                               (toggle-tree obj)
                                                                               (toggle-tree obj)))
                                                                           :title "New Directory")))
                                                     :cancel-event t)
                                       (set-on-mouse-leave menu (lambda (obj) (destroy obj)))))))))
      (set-on-change root-dir #'on-change)
      (on-change obj))))